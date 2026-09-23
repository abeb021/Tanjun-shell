from __future__ import annotations

import json
import os
import time

from lib import QS_BIN, Qs, run
from pathlib import Path


def _truthy(text: str) -> bool:
    return text.strip().lower() in ("true", "1")


def _json_cmd(cmd: list[str]):
    r = run(cmd, timeout=3)
    if r.returncode != 0:
        return None
    try:
        return json.loads((r.stdout or "").strip() or "null")
    except json.JSONDecodeError:
        return None


def _compositor_desks() -> tuple[set[int] | None, int | None, set[int] | None]:
    """Windows on desks 1-10, focused id, and ids active on any monitor."""
    if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        clients = _json_cmd(["hyprctl", "clients", "-j"])
        current = _json_cmd(["hyprctl", "activeworkspace", "-j"])
        mons = _json_cmd(["hyprctl", "monitors", "-j"])
        if not isinstance(clients, list):
            return None, None, None
        occ: set[int] = set()
        for c in clients:
            if not isinstance(c, dict):
                continue
            if c.get("hidden") or c.get("mapped") is False:
                continue
            ws = c.get("workspace") or {}
            n = int((ws.get("id") if isinstance(ws, dict) else 0) or 0)
            if 1 <= n <= 10:
                occ.add(n)
        focused = int((current or {}).get("id") or 0) if isinstance(current, dict) else 0
        active: set[int] = set()
        if isinstance(mons, list):
            for m in mons:
                if not isinstance(m, dict):
                    continue
                aw = m.get("activeWorkspace") or {}
                n = int((aw.get("id") if isinstance(aw, dict) else 0) or 0)
                if 1 <= n <= 10:
                    active.add(n)
        if 1 <= focused <= 10:
            active.add(focused)
        return occ, focused, active
    if os.environ.get("NIRI_SOCKET"):
        windows = _json_cmd(["niri", "msg", "--json", "windows"])
        workspaces = _json_cmd(["niri", "msg", "--json", "workspaces"])
        if not isinstance(windows, list) or not isinstance(workspaces, list):
            return None, None, None
        id_to_idx = {}
        focused = 0
        active = set()
        for ws in workspaces:
            if not isinstance(ws, dict):
                continue
            wid = ws.get("id")
            idx = int(ws.get("idx") or 0)
            if wid is not None:
                id_to_idx[wid] = idx
            if 1 <= idx <= 10 and (ws.get("is_active") or ws.get("is_focused")):
                active.add(idx)
            if ws.get("is_focused"):
                focused = idx
        occ = set()
        for w in windows:
            if not isinstance(w, dict):
                continue
            idx = int(id_to_idx.get(w.get("workspace_id")) or 0)
            if 1 <= idx <= 10:
                occ.add(idx)
        return occ, focused, active
    return None, None, None


def register(s) -> None:
    s.ok("qs on PATH", bool(QS_BIN), "qs not on PATH")
    s.ok("wayland display", bool(os.environ.get("WAYLAND_DISPLAY")), "WAYLAND_DISPLAY unset")
    if not QS_BIN or not os.environ.get("WAYLAND_DISPLAY"):
        return

    qs = Qs()
    user_cfg = Path.home() / ".config" / "tanjun" / "config.json"
    user_before = user_cfg.read_bytes() if user_cfg.is_file() else b""
    err = qs.start()
    saved_style = None
    try:
        s.ok("qs running", not err, (err or qs.log)[-800:])
        if err:
            return
        s.ok("qs owned instance", qs.owned, "harness must not attach to live shell")
        s.ok("qs configuration loaded", "Configuration Loaded" in (qs.log or ""), (qs.log or "")[-400:])
        s.eq("owned qs skips user config", user_cfg.read_bytes() if user_cfg.is_file() else b"", user_before)

        out = ""
        show = None
        deadline = time.time() + 6
        while time.time() < deadline:
            show = qs.ipc("show")
            out = (show.stdout or "") + (show.stderr or "")
            if "function ping" in out:
                break
            time.sleep(0.2)
        s.eq("ipc show exit", show.returncode if show else 1, 0)
        s.ok("ipc target tanjun", "target tanjun" in out, out[-400:])
        for fn in (
            "ping",
            "themeJson",
            "configJson",
            "toggleSettings",
            "toggleLauncher",
            "toggleClipboard",
            "toggleSidebar",
            "closeMenus",
            "toggleDnd",
            "settingsPages",
            "openSettingsPage",
            "snapScale",
            "setStyle",
            "setTheme",
            "setWallpaper",
            "setSampleWall",
            "openWalls",
            "setWallFolder",
            "pickWall",
            "styles",
            "styleJson",
            "motionStyles",
            "motionJson",
            "setMotion",
            "pollJson",
            "hostCaps",
            "settingsCatalog",
            "uiMode",
            "toggleOverview",
            "launcherJson",
            "workspaceJson",
            "lock",
            "unlock",
            "lockJson",
            "logout",
            "sunsetJson",
            "setSunset",
            "deskJson",
            "setDesk",
            "idleJson",
            "setIdle",
            "sidebarJson",
            "popJson",
        ):
            s.ok(f"ipc has {fn}", f"function {fn}" in out, out[-400:])

        ping = qs.ipc("call", "tanjun", "ping")
        s.eq("ping exit", ping.returncode, 0)
        s.eq("ping", (ping.stdout or "").strip(), "ok")
        locked = qs.ipc("prop", "get", "tanjun", "locked")
        s.ok("session not locked", not _truthy(locked.stdout or ""), locked.stdout)

        lock_raw = qs.ipc("call", "tanjun", "lockJson")
        s.eq("lockJson exit", lock_raw.returncode, 0)
        try:
            lock_info = json.loads((lock_raw.stdout or "").strip() or "{}")
            lock_err = ""
        except json.JSONDecodeError as e:
            lock_info = {}
            lock_err = str(e)
        s.ok("lockJson json", isinstance(lock_info, dict) and not lock_err, lock_err or str(lock_info))
        s.ok("lockJson idle unlocked", lock_info.get("locked") is False, str(lock_info))
        s.eq("lock leave Super+O", lock_info.get("leaveSeq") or "", "Meta+O")
        s.ok("lock test host", lock_info.get("testHost") is True, str(lock_info))
        s.ok("qs alive before lock", qs.proc is not None and qs.proc.poll() is None)

        locked_on = qs.ipc("call", "tanjun", "lock")
        s.eq("lock ipc exit", locked_on.returncode, 0)
        deadline = time.time() + 2
        locked_prop = ""
        while time.time() < deadline:
            locked_prop = (qs.ipc("prop", "get", "tanjun", "locked").stdout or "").strip()
            if _truthy(locked_prop):
                break
            time.sleep(0.1)
        s.ok("lock ipc locks", _truthy(locked_prop), locked_prop)
        s.ok("qs alive while locked", qs.proc is not None and qs.proc.poll() is None, "lock killed qs")
        try:
            lock_info = json.loads((qs.ipc("call", "tanjun", "lockJson").stdout or "").strip() or "{}")
        except json.JSONDecodeError:
            lock_info = {}
        s.ok("lockJson locked", lock_info.get("locked") is True, str(lock_info))
        s.eq("lock leave Super+O while locked", lock_info.get("leaveSeq") or "", "Meta+O")
        pam_lock = f"{lock_info.get('pamDir') or ''}"
        s.ok("lock pamDir set", pam_lock.endswith("/pam") or "/tanjun/pam" in pam_lock or pam_lock.endswith("shell/pam"), pam_lock)

        left = qs.ipc("call", "tanjun", "logout")
        s.eq("lock leave logout exit", left.returncode, 0)
        deadline = time.time() + 2
        unlocked_prop = "true"
        while time.time() < deadline:
            if qs.proc is None or qs.proc.poll() is not None:
                break
            unlocked_prop = (qs.ipc("prop", "get", "tanjun", "locked").stdout or "").strip()
            if not _truthy(unlocked_prop):
                break
            time.sleep(0.1)
        s.ok("qs alive after lock leave", qs.proc is not None and qs.proc.poll() is None, "logout killed the harness")
        s.ok("lock leave unlocks", not _truthy(unlocked_prop), unlocked_prop)

        qs.ipc("call", "tanjun", "closeMenus")
        time.sleep(0.2)
        ready = qs.ipc("prop", "get", "tanjun", "settingsReady")
        s.ok("settings not preloaded", not _truthy(ready.stdout or ""), ready.stdout)
        s.ok("launcher not preloaded", not _truthy((qs.ipc("prop", "get", "tanjun", "launcherReady").stdout or "")), "")

        def _maps() -> str:
            pid = qs.proc.pid if qs.proc else 0
            if not pid:
                return ""
            try:
                return Path(f"/proc/{pid}/maps").read_text(errors="replace")
            except OSError:
                return ""

        def _ram() -> dict[str, int]:
            out = {"rss": 0, "anon": 0}
            pid = qs.proc.pid if qs.proc else 0
            if not pid:
                return out
            try:
                for line in Path(f"/proc/{pid}/status").read_text().splitlines():
                    if line.startswith("VmRSS:"):
                        out["rss"] = int(line.split()[1])
                    elif line.startswith("RssAnon:"):
                        out["anon"] = int(line.split()[1])
            except (OSError, ValueError):
                return out
            return out

        def _ram_msg(row: dict[str, int]) -> str:
            return f"{row.get('rss') or 0} kB rss  {row.get('anon') or 0} kB anon"

        maps = _maps()
        s.ok("idle qs maps readable", bool(maps), "no /proc maps")
        s.ok("idle skips CJK font", "NotoSansCJK" not in maps, "NotoSansCJK still mapped")
        s.ok("idle skips color emoji", "NotoColorEmoji" not in maps, "NotoColorEmoji still mapped")
        s.ok("idle skips Mesa LLVM", "libLLVM" not in maps, "libLLVM still mapped")
        s.ok("idle skips gallium", "libgallium" not in maps, "libgallium still mapped")
        ram_idle = _ram()
        s.ok("ram idle measured", ram_idle["rss"] > 0, _ram_msg(ram_idle))
        s.ok("ram idle under 200M", ram_idle["rss"] <= 204800, _ram_msg(ram_idle))
        s.ok("ram idle anon under 140M", ram_idle["anon"] <= 143360, _ram_msg(ram_idle))

        def _poll() -> dict:
            raw_poll = qs.ipc("call", "tanjun", "pollJson")
            s.eq("pollJson exit", raw_poll.returncode, 0)
            try:
                return json.loads((raw_poll.stdout or "").strip() or "{}")
            except json.JSONDecodeError:
                return {}

        idle = _poll()
        s.ok("pollJson object", isinstance(idle, dict), str(idle))
        s.ok("host idle", idle.get("host") is False, str(idle))
        s.ok("vpn idle", idle.get("vpn") is False, str(idle))
        s.ok("weather idle", idle.get("weather") is False, str(idle))
        s.ok("mixer idle", idle.get("mixer") is False, str(idle))
        s.eq("backlight idle ms", idle.get("backlightMs"), 0)
        s.ok("idleInhibited bool", isinstance(idle.get("idleInhibited"), bool), str(idle))

        caps_raw = qs.ipc("call", "tanjun", "hostCaps")
        s.eq("hostCaps exit", caps_raw.returncode, 0)
        try:
            caps = json.loads((caps_raw.stdout or "").strip() or "{}")
            caps_err = ""
        except json.JSONDecodeError as e:
            caps = {}
            caps_err = str(e)
        s.ok("hostCaps json", isinstance(caps, dict) and not caps_err, caps_err or str(caps))
        wall_dir = f"{caps.get('wallDir') or ''}"
        s.ok("wallDir set", "/tanjun/" in wall_dir or wall_dir.endswith("walls"), wall_dir)
        s.ok("wallDir not hypr-owned", "/hypr/" not in wall_dir, wall_dir)
        s.ok("hostCaps hasGamma bool", isinstance(caps.get("hasGamma"), bool), str(caps))
        s.ok("hostCaps grabFocus bool", isinstance(caps.get("grabFocus"), bool), str(caps))
        s.ok("hostCaps idleInhibited bool", isinstance(caps.get("idleInhibited"), bool), str(caps))
        contract = caps.get("contract")
        s.ok("hostCaps contract list", isinstance(contract, list) and len(contract) >= 8, str(contract))
        for key in ("hasGamma", "grabFocus", "idleInhibited", "persistMonitors", "setDpms", "windows"):
            s.ok(f"contract has {key}", isinstance(contract, list) and key in contract, str(contract))
        pam_dir = f"{caps.get('pamDir') or ''}"
        s.ok("pamDir set", pam_dir.endswith("/pam") or "/tanjun/pam" in pam_dir or pam_dir.endswith("shell/pam"), pam_dir)
        s.ok("pamDir not world path junk", ".." not in pam_dir, pam_dir)

        ws_raw = qs.ipc("call", "tanjun", "workspaceJson")
        s.eq("workspaceJson exit", ws_raw.returncode, 0)
        try:
            desks = json.loads((ws_raw.stdout or "").strip() or "{}")
            desks_err = ""
        except json.JSONDecodeError as e:
            desks = {}
            desks_err = str(e)
        s.ok("workspaceJson json", isinstance(desks, dict) and not desks_err, desks_err or str(desks))
        ids = desks.get("ids") if isinstance(desks, dict) else None
        occupied = desks.get("occupied") if isinstance(desks, dict) else None
        focused = int(desks.get("focused") or 0) if isinstance(desks, dict) else 0
        s.ok("workspace ids list", isinstance(ids, list) and all(isinstance(n, int) for n in (ids or [])), str(ids))
        s.ok("workspace occupied list", isinstance(occupied, list) and all(isinstance(n, int) for n in (occupied or [])), str(occupied))
        if isinstance(ids, list):
            s.ok("workspace ids unique", len(ids) == len(set(ids)), str(ids))
            for n in (1, 2, 3):
                s.ok(f"workspace always shows {n}", n in ids, str(ids))
            extras = [n for n in ids if n > 3]
            occ_set = set(occupied or [])
            active_set = set(desks.get("active") or [])
            for n in extras:
                s.ok(
                    f"extra desk {n} occupied, focused, or on a monitor",
                    n in occ_set or n == focused or n in active_set,
                    str(desks),
                )
        live_occ, live_focus, live_active = _compositor_desks()
        if live_occ is not None:
            deadline = time.time() + 1.5
            while time.time() < deadline:
                ws_raw = qs.ipc("call", "tanjun", "workspaceJson")
                try:
                    desks = json.loads((ws_raw.stdout or "").strip() or "{}")
                except json.JSONDecodeError:
                    desks = {}
                occupied = desks.get("occupied") if isinstance(desks, dict) else None
                ids = desks.get("ids") if isinstance(desks, dict) else None
                live_occ, live_focus, live_active = _compositor_desks()
                want_ids = sorted(
                    set([1, 2, 3])
                    | (live_occ or set())
                    | (live_active or set())
                    | ({live_focus} if 1 <= int(live_focus or 0) <= 10 else set())
                )
                if (
                    isinstance(occupied, list)
                    and isinstance(ids, list)
                    and live_occ is not None
                    and sorted(occupied) == sorted(live_occ)
                    and sorted(ids) == want_ids
                ):
                    break
                time.sleep(0.1)
            focused = int(desks.get("focused") or 0) if isinstance(desks, dict) else 0
            s.eq("workspace occupied matches windows", sorted(occupied or []), sorted(live_occ or []))
            s.eq("workspace active matches monitors", sorted(desks.get("active") or []), sorted(live_active or []))
            s.eq("workspace ids match occupied+pinned", sorted(ids or []), want_ids)
            on_out = desks.get("onOutput") if isinstance(desks, dict) else None
            s.ok("workspace onOutput map", isinstance(on_out, dict), str(on_out))
            live_on = {}
            if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
                mons = _json_cmd(["hyprctl", "monitors", "-j"])
                if isinstance(mons, list):
                    for m in mons:
                        if not isinstance(m, dict):
                            continue
                        name = f"{m.get('name') or ''}"
                        aw = m.get("activeWorkspace") or {}
                        n = int((aw.get("id") if isinstance(aw, dict) else 0) or 0)
                        if name and 1 <= n <= 10:
                            live_on[name] = n
            elif os.environ.get("NIRI_SOCKET"):
                workspaces = _json_cmd(["niri", "msg", "--json", "workspaces"])
                if isinstance(workspaces, list):
                    for ws in workspaces:
                        if not isinstance(ws, dict):
                            continue
                        if not (ws.get("is_active") or ws.get("is_focused")):
                            continue
                        name = f"{ws.get('output') or ''}"
                        n = int(ws.get("idx") or 0)
                        if name and 1 <= n <= 10:
                            live_on[name] = n
            if live_on and isinstance(on_out, dict):
                for name, n in live_on.items():
                    got = int(on_out.get(name) or 0)
                    s.eq(f"workspace active on {name}", got, n)
                s.ok("workspace onOutput covers monitors", len(on_out) >= len(live_on), str(on_out))

        raw = qs.ipc("call", "tanjun", "themeJson")
        s.eq("themeJson exit", raw.returncode, 0)
        try:
            theme = json.loads((raw.stdout or "").strip() or "{}")
            parse_err = ""
        except json.JSONDecodeError as e:
            theme = {}
            parse_err = str(e)
        s.ok("themeJson json", isinstance(theme, dict) and not parse_err, parse_err or (raw.stdout or "")[:200])
        for key in ("accent", "bg", "fg", "surface", "name"):
            s.ok(f"theme has {key}", key in theme, str(theme.keys()))
        theme_wall = f"{theme.get('wallDir') or ''}"
        s.ok("theme wallDir set", "/tanjun/" in theme_wall or theme_wall.endswith("walls"), theme_wall)
        s.ok("theme wallDir not hypr-owned", "/hypr/" not in theme_wall, theme_wall)

        cfg_raw = qs.ipc("call", "tanjun", "configJson")
        s.eq("configJson exit", cfg_raw.returncode, 0)
        try:
            cfg = json.loads((cfg_raw.stdout or "").strip() or "{}")
            cfg_err = ""
        except json.JSONDecodeError as e:
            cfg = None
            cfg_err = str(e)
        s.ok("configJson json", isinstance(cfg, dict) and not cfg_err, cfg_err or (cfg_raw.stdout or "")[:200])

        mode_raw = qs.ipc("call", "tanjun", "uiMode")
        s.eq("uiMode exit", mode_raw.returncode, 0)
        try:
            mode = json.loads((mode_raw.stdout or "").strip() or "{}")
            mode_err = ""
        except json.JSONDecodeError as e:
            mode = {}
            mode_err = str(e)
        s.ok("uiMode json", isinstance(mode, dict) and not mode_err, mode_err or str(mode))
        s.eq("uiMode idle kind", mode.get("kind") or "", "")
        s.ok("uiMode settings not ready", mode.get("settingsReady") is False, str(mode))
        s.ok("uiMode overview not ready", mode.get("overviewReady") is False, str(mode))
        s.ok("uiMode launcher not ready", mode.get("launcherReady") is False, str(mode))
        s.eq("uiMode idle overview pick", mode.get("overviewPick") or "", "")
        s.eq("uiMode idle overview count", int(mode.get("overviewCount") or 0), 0)
        s.ok("uiMode idle walls closed", mode.get("wallsOpen") is False, str(mode))
        s.ok("uiMode sidebar not ready", mode.get("sidebarReady") is False, str(mode))
        s.eq("uiMode idle popout keep", mode.get("popoutKeep") or "", "")

        cat_raw = qs.ipc("call", "tanjun", "settingsCatalog")
        s.eq("settingsCatalog exit", cat_raw.returncode, 0)
        try:
            catalog = json.loads((cat_raw.stdout or "").strip() or "[]")
            cat_err = ""
        except json.JSONDecodeError as e:
            catalog = []
            cat_err = str(e)
        s.ok("settingsCatalog list", isinstance(catalog, list) and not cat_err, cat_err or str(catalog))
        titles = [f"{row.get('title') if isinstance(row, dict) else row}" for row in catalog]
        for title in ("system", "sound", "type", "From wall", "Monochrome", "Minimal", "Chrome", "Night light", "Night at", "Day at", "battery", "Dim", "Sleep", "Hibernate", "Quiet", "Snappy", "Instant"):
            s.ok(f"catalog has {title}", title in titles, str(titles[:20]))

        qs.ipc("call", "tanjun", "closeMenus")
        time.sleep(0.15)
        closed = qs.ipc("prop", "get", "tanjun", "settingsOpen")
        s.ok("settings closed before toggle", not _truthy(closed.stdout or ""), closed.stdout)

        opened = qs.ipc("call", "tanjun", "toggleSettings")
        s.eq("toggleSettings exit", opened.returncode, 0)
        rail_n = "0"
        deadline = time.time() + 2
        while time.time() < deadline:
            now = qs.ipc("prop", "get", "tanjun", "settingsOpen")
            rail_n = (qs.ipc("prop", "get", "tanjun", "settingsRailCount").stdout or "").strip()
            if _truthy(now.stdout or "") and rail_n == "12":
                break
            time.sleep(0.05)
        s.ok("settings opened", _truthy((qs.ipc("prop", "get", "tanjun", "settingsOpen").stdout or "")), "")
        s.ok("settings ready after toggle", _truthy((qs.ipc("prop", "get", "tanjun", "settingsReady").stdout or "")), "")
        ram_settings = _ram()
        s.ok("ram settings measured", ram_settings["rss"] > 0, _ram_msg(ram_settings))
        s.ok("ram settings under 280M", ram_settings["rss"] <= 286720, _ram_msg(ram_settings))
        busy_mode = json.loads((qs.ipc("call", "tanjun", "uiMode").stdout or "").strip() or "{}")
        s.eq("uiMode settings kind", busy_mode.get("kind"), "settings")
        busy = _poll()
        s.ok("host ticks in settings", busy.get("host") is True, str(busy))
        s.ok("weather idle on system page", busy.get("weather") is False, str(busy))
        s.ok("vpn idle on system page", busy.get("vpn") is False, str(busy))
        qs.ipc("call", "tanjun", "openSettingsPage", "system")
        time.sleep(0.1)
        page = (qs.ipc("prop", "get", "tanjun", "settingsPage").stdout or "").strip()
        s.eq("settings opens on system", page, "system")
        pages_raw = qs.ipc("call", "tanjun", "settingsPages")
        s.eq("settingsPages exit", pages_raw.returncode, 0)
        try:
            pages = json.loads((pages_raw.stdout or "").strip() or "[]")
            pages_err = ""
        except json.JSONDecodeError as e:
            pages = []
            pages_err = str(e)
        s.ok("settingsPages json", isinstance(pages, list) and not pages_err, pages_err or str(pages))
        for pid in ("system", "sound", "screen", "battery", "network", "bluetooth", "type", "clock", "weather", "devices", "style", "color"):
            s.ok(f"settings has {pid}", pid in pages, str(pages))
        s.ok("settings has no session", "session" not in pages, str(pages))
        s.ok("battery after screen", pages.index("battery") == pages.index("screen") + 1 if "battery" in pages and "screen" in pages else False, str(pages))
        s.ok("style before color", pages.index("style") < pages.index("color") if "style" in pages and "color" in pages else False, str(pages))
        switched = qs.ipc("call", "tanjun", "openSettingsPage", "sound")
        s.eq("openSettingsPage exit", switched.returncode, 0)
        time.sleep(0.1)
        s.eq(
            "settings page sound",
            (qs.ipc("prop", "get", "tanjun", "settingsPage").stdout or "").strip(),
            "sound",
        )
        sound_poll = _poll()
        s.ok("mixer live on sound page", sound_poll.get("mixer") is True, str(sound_poll))
        s.ok("host idle on sound page", sound_poll.get("host") is False, str(sound_poll))
        qs.ipc("call", "tanjun", "openSettingsPage", "system")
        time.sleep(0.2)
        rail_n = (qs.ipc("prop", "get", "tanjun", "settingsRailCount").stdout or "").strip()
        s.eq("settings rail count", rail_n, "12")
        try:
            rail_h = int((qs.ipc("prop", "get", "tanjun", "settingsRailH").stdout or "0").strip())
        except ValueError:
            rail_h = 0
        s.ok("settings rail visible", rail_h >= 200, f"height {rail_h}")
        for pid in ("network", "bluetooth", "screen", "battery", "type", "clock", "weather", "devices", "style", "color"):
            qs.ipc("call", "tanjun", "openSettingsPage", pid)
            page_now = ""
            deadline = time.time() + 1.5
            while time.time() < deadline:
                page_now = (qs.ipc("prop", "get", "tanjun", "settingsPage").stdout or "").strip()
                if page_now == pid:
                    break
                time.sleep(0.05)
            s.eq(f"settings page {pid}", page_now, pid)
            try:
                sy = int((qs.ipc("prop", "get", "tanjun", "settingsScrollY").stdout or "0").strip())
            except ValueError:
                sy = 999
            s.ok(f"settings {pid} at top", sy <= 2, f"scroll {sy}")
            if pid == "style":
                n = (qs.ipc("prop", "get", "tanjun", "settingsStyleCount").stdout or "").strip()
                s.eq("settings style cards", n, "2")
            if pid == "weather":
                wp = _poll()
                s.ok("weather live on weather page", wp.get("weather") is True, str(wp))
                s.ok("host idle on weather page", wp.get("host") is False, str(wp))
            if pid in ("network", "bluetooth"):
                try:
                    gap = int((qs.ipc("prop", "get", "tanjun", "settingsToggleGap").stdout or "-1").strip())
                except ValueError:
                    gap = -1
                s.ok(f"settings {pid} toggle inset", 8 <= gap <= 32, f"gap {gap}")
            if pid == "network":
                npoll = _poll()
                s.ok("vpn live on network page", npoll.get("vpn") is True, str(npoll))
                s.ok("host idle on network page", npoll.get("host") is False, str(npoll))
        qs.ipc("call", "tanjun", "openSettingsPage", "system")

        styles_raw = qs.ipc("call", "tanjun", "styles")
        s.eq("styles exit", styles_raw.returncode, 0)
        try:
            style_keys = json.loads((styles_raw.stdout or "").strip() or "[]")
            styles_err = ""
        except json.JSONDecodeError as e:
            style_keys = []
            styles_err = str(e)
        s.ok("styles json", isinstance(style_keys, list) and not styles_err, styles_err or str(style_keys))
        for sid in ("minimal", "chrome"):
            s.ok(f"style has {sid}", sid in style_keys, str(style_keys))
        s.ok("style has no tanjun key", "tanjun" not in style_keys, str(style_keys))
        s.ok("style has no panel key", "panel" not in style_keys, str(style_keys))
        prior_style = (qs.ipc("prop", "get", "tanjun", "style").stdout or "").strip()
        saved_style = prior_style or "chrome"
        prior_theme = json.loads((qs.ipc("call", "tanjun", "themeJson").stdout or "").strip() or "{}")
        other = "minimal" if prior_style != "minimal" else "chrome"
        flipped = qs.ipc("call", "tanjun", "setStyle", other)
        s.eq("setStyle exit", flipped.returncode, 0)
        time.sleep(0.15)
        s.eq("style switched", (qs.ipc("prop", "get", "tanjun", "style").stdout or "").strip(), other)
        after_theme = json.loads((qs.ipc("call", "tanjun", "themeJson").stdout or "").strip() or "{}")
        s.eq("style leaves palette", after_theme.get("name"), prior_theme.get("name"))
        chrome_raw = qs.ipc("call", "tanjun", "styleJson")
        s.eq("styleJson exit", chrome_raw.returncode, 0)
        try:
            chrome = json.loads((chrome_raw.stdout or "").strip() or "{}")
            chrome_err = ""
        except json.JSONDecodeError as e:
            chrome = {}
            chrome_err = str(e)
        s.ok("styleJson json", isinstance(chrome, dict) and not chrome_err, chrome_err or (chrome_raw.stdout or "")[:120])
        s.eq("styleJson key", chrome.get("key"), other)
        s.eq("styleJson tick", chrome.get("tick"), other == "chrome")
        s.eq("styleJson tickPops", chrome.get("tickPops"), False)
        s.eq("styleJson chipBorder", chrome.get("chipBorder"), 1 if other == "chrome" else 0)
        s.eq("styleJson pip", chrome.get("pip"), other == "chrome")
        s.ok("themeJson has no tick", "tick" not in after_theme, str(after_theme.keys()))
        s.ok("themeJson has no chipBorder", "chipBorder" not in after_theme, str(after_theme.keys()))
        cfg_style = json.loads((qs.ipc("call", "tanjun", "configJson").stdout or "").strip() or "{}")
        ap = cfg_style.get("appearance") if isinstance(cfg_style, dict) else None
        if other == "chrome":
            s.ok(
                "default style omitted from config",
                not isinstance(ap, dict) or ap.get("style") in (None, "", "chrome"),
                str(ap),
            )
        else:
            s.eq("config appearance.style", (ap or {}).get("style"), other)
        alias_panel = qs.ipc("call", "tanjun", "setStyle", "panel")
        s.eq("panel alias exit", alias_panel.returncode, 0)
        time.sleep(0.1)
        s.eq("panel alias is chrome", (qs.ipc("prop", "get", "tanjun", "style").stdout or "").strip(), "chrome")
        alias_min = qs.ipc("call", "tanjun", "setStyle", "tanjun")
        s.eq("tanjun alias exit", alias_min.returncode, 0)
        time.sleep(0.1)
        s.eq("tanjun alias is minimal", (qs.ipc("prop", "get", "tanjun", "style").stdout or "").strip(), "minimal")
        qs.ipc("call", "tanjun", "openSettingsPage", "network")
        time.sleep(0.15)
        try:
            rad = int((qs.ipc("prop", "get", "tanjun", "settingsToggleRadius").stdout or "-1").strip())
        except ValueError:
            rad = -1
        s.eq("wifi toggle square in minimal", rad, 1)
        qs.ipc("call", "tanjun", "setStyle", "chrome")
        time.sleep(0.1)
        qs.ipc("call", "tanjun", "openSettingsPage", "network")
        time.sleep(0.15)
        try:
            rad = int((qs.ipc("prop", "get", "tanjun", "settingsToggleRadius").stdout or "-1").strip())
        except ValueError:
            rad = -1
        s.eq("wifi toggle square in chrome", rad, 1)
        qs.ipc("call", "tanjun", "setStyle", prior_style or "chrome")
        time.sleep(0.1)
        s.eq(
            "style restored",
            (qs.ipc("prop", "get", "tanjun", "style").stdout or "").strip(),
            prior_style or "chrome",
        )

        motion_keys_raw = qs.ipc("call", "tanjun", "motionStyles")
        s.eq("motionStyles exit", motion_keys_raw.returncode, 0)
        try:
            motion_keys = json.loads((motion_keys_raw.stdout or "").strip() or "[]")
            motion_keys_err = ""
        except json.JSONDecodeError as e:
            motion_keys = []
            motion_keys_err = str(e)
        s.ok("motionStyles json", isinstance(motion_keys, list) and not motion_keys_err, motion_keys_err or str(motion_keys))
        for mid in ("instant", "quiet", "snappy", "soft"):
            s.ok(f"motion has {mid}", mid in motion_keys, str(motion_keys))
        quiet_raw = qs.ipc("call", "tanjun", "motionJson")
        s.eq("motionJson exit", quiet_raw.returncode, 0)
        try:
            quiet_motion = json.loads((quiet_raw.stdout or "").strip() or "{}")
        except json.JSONDecodeError:
            quiet_motion = {}
        s.eq("motion default quiet", quiet_motion.get("key"), "quiet")
        s.eq("motion quiet pop", int(quiet_motion.get("pop") or 0), 220)
        s.eq("motion quiet popY", int(quiet_motion.get("popY") or 0), 10)
        s.eq("motion quiet panelY", int(quiet_motion.get("panelY") or 0), 18)
        s.eq("motion quiet toastX", int(quiet_motion.get("toastX") or 0), 32)
        s.ok("motion quiet press", 0.9 <= float(quiet_motion.get("pressFrom") or 0) < 1, str(quiet_motion))
        snap = qs.ipc("call", "tanjun", "setMotion", "snappy")
        s.eq("setMotion snappy exit", snap.returncode, 0)
        try:
            snap_motion = json.loads((snap.stdout or "").strip() or "{}")
        except json.JSONDecodeError:
            snap_motion = {}
        s.eq("setMotion snappy key", snap_motion.get("key"), "snappy")
        s.ok("setMotion snappy faster pop", int(snap_motion.get("pop") or 0) < 220, str(snap_motion))
        s.ok("setMotion snappy travels", int(snap_motion.get("popY") or 0) > 0, str(snap_motion))
        s.eq("setMotion snappy spring", snap_motion.get("spring"), True)
        s.eq("motion prop snappy", (qs.ipc("prop", "get", "tanjun", "motion").stdout or "").strip(), "snappy")
        cfg_motion = json.loads((qs.ipc("call", "tanjun", "configJson").stdout or "").strip() or "{}")
        ap_motion = cfg_motion.get("appearance") if isinstance(cfg_motion, dict) else None
        s.eq("config appearance.motion", (ap_motion or {}).get("motion"), "snappy")
        instant = qs.ipc("call", "tanjun", "setMotion", "off")
        s.eq("setMotion off exit", instant.returncode, 0)
        try:
            instant_motion = json.loads((instant.stdout or "").strip() or "{}")
        except json.JSONDecodeError:
            instant_motion = {}
        s.eq("setMotion off is instant", instant_motion.get("key"), "instant")
        s.eq("setMotion instant pop", int(instant_motion.get("pop") or 0), 1)
        s.eq("setMotion instant popY", int(instant_motion.get("popY") or 0), 0)
        s.eq("setMotion instant toastX", int(instant_motion.get("toastX") or 0), 0)
        s.eq("setMotion instant pressFrom", float(instant_motion.get("pressFrom") or 0), 1.0)
        s.eq("setMotion instant spring", instant_motion.get("spring"), False)
        qs.ipc("call", "tanjun", "setMotion", "quiet")
        time.sleep(0.1)
        after_quiet = json.loads((qs.ipc("call", "tanjun", "motionJson").stdout or "").strip() or "{}")
        s.eq("motion restored quiet", after_quiet.get("key"), "quiet")
        cfg_quiet = json.loads((qs.ipc("call", "tanjun", "configJson").stdout or "").strip() or "{}")
        ap_quiet = cfg_quiet.get("appearance") if isinstance(cfg_quiet, dict) else None
        s.ok(
            "default motion omitted from config",
            not isinstance(ap_quiet, dict) or ap_quiet.get("motion") in (None, "", "quiet"),
            str(ap_quiet),
        )
        user_after = user_cfg.read_bytes() if user_cfg.is_file() else b""
        s.eq("tests leave user config", user_after, user_before)

        qs.ipc("call", "tanjun", "toggleAudio")
        pop = {}
        pop_mode = {}
        deadline = time.time() + 2
        while time.time() < deadline:
            pop_mode = json.loads((qs.ipc("call", "tanjun", "uiMode").stdout or "").strip() or "{}")
            try:
                pop = json.loads((qs.ipc("call", "tanjun", "popJson").stdout or "").strip() or "{}")
            except json.JSONDecodeError:
                pop = {}
            if pop.get("open") is True and pop.get("grow") == "down" and pop_mode.get("popoutKeep") == "audio":
                break
            time.sleep(0.05)
        s.ok("bar pop open", pop.get("open") is True, str(pop))
        s.eq("bar pop keep", pop_mode.get("popoutKeep"), "audio")
        s.eq("bar pop grow", pop.get("grow"), "down")
        s.eq("bar pop origin", pop.get("origin"), "top")
        s.eq("bar pop scaleX", float(pop.get("scaleX") if pop.get("scaleX") is not None else 0), 1.0)
        s.ok("bar pop drops", int(pop.get("fromY") or 0) < 0, str(pop))
        s.ok("mixer live in audio pop", _poll().get("mixer") is True, str(_poll()))
        qs.ipc("call", "tanjun", "closeMenus")
        s.eq("bar pop closed", (qs.ipc("prop", "get", "tanjun", "popout").stdout or "").strip(), "")
        s.ok("mixer idle while pop exits", _poll().get("mixer") is False, str(_poll()))
        dropped_pop = False
        deadline = time.time() + 1.2
        while time.time() < deadline:
            pop_mode = json.loads((qs.ipc("call", "tanjun", "uiMode").stdout or "").strip() or "{}")
            if not (pop_mode.get("popoutKeep") or ""):
                dropped_pop = True
                break
            time.sleep(0.05)
        s.ok("bar pop dropped after close", dropped_pop, "popoutKeep stayed set")

        snap_cases = (("1.19", 1.2), ("1.27", 1.25), ("1", 1), ("1.9", 2), ("1.6", 1.5), ("1.2", 1.2))
        for raw, want in snap_cases:
            got = qs.ipc("call", "tanjun", "snapScale", raw)
            s.eq(f"snapScale {raw} exit", got.returncode, 0)
            try:
                val = json.loads((got.stdout or "").strip() or "null")
                err = ""
            except json.JSONDecodeError as e:
                val = None
                err = str(e)
            s.ok(f"snapScale {raw} json", val is not None and not err, err or (got.stdout or "")[:80])
            s.eq(f"snapScale {raw}", val, want)

        sun_raw = qs.ipc("call", "tanjun", "sunsetJson")
        s.eq("sunsetJson exit", sun_raw.returncode, 0)
        try:
            sun = json.loads((sun_raw.stdout or "").strip() or "{}")
            sun_err = ""
        except json.JSONDecodeError as e:
            sun = {}
            sun_err = str(e)
        s.ok("sunsetJson json", isinstance(sun, dict) and not sun_err, sun_err or str(sun))
        s.ok("sunset nightAt clock", isinstance(sun.get("nightAt"), str) and ":" in f"{sun.get('nightAt')}", str(sun))
        s.ok("sunset dayAt clock", isinstance(sun.get("dayAt"), str) and ":" in f"{sun.get('dayAt')}", str(sun))
        s.ok("sunset on by default", sun.get("on") is True, str(sun))
        set_sun = qs.ipc("call", "tanjun", "setSunset", '{"nightAt":"22:15","dayAt":"6:00","nightTemp":4000,"on":true}')
        s.eq("setSunset exit", set_sun.returncode, 0)
        try:
            after_sun = json.loads((set_sun.stdout or "").strip() or "{}")
        except json.JSONDecodeError:
            after_sun = {}
        s.eq("setSunset nightAt", after_sun.get("nightAt"), "22:15")
        s.eq("setSunset dayAt", after_sun.get("dayAt"), "6:00")
        s.eq("setSunset nightTemp", int(after_sun.get("nightTemp") or 0), 4000)
        s.eq("setSunset on", after_sun.get("on"), True)
        cfg_sun = json.loads((qs.ipc("call", "tanjun", "configJson").stdout or "").strip() or "{}")
        screens_cfg = cfg_sun.get("screens") if isinstance(cfg_sun, dict) else None
        s.ok("config screens object after sunset", isinstance(screens_cfg, dict), str(cfg_sun))
        if isinstance(screens_cfg, dict):
            s.eq("config nightAt", screens_cfg.get("nightAt"), "22:15")
            s.eq("config dayAt", screens_cfg.get("dayAt"), "6:00")
        sun_path = Path(qs.home) / "config" / "hypr" / "hyprsunset.conf" if qs.home else None
        deadline = time.time() + 2
        while sun_path and time.time() < deadline:
            if sun_path.is_file() and "temperature = 4000" in sun_path.read_text(encoding="utf-8"):
                break
            time.sleep(0.05)
        s.ok("hyprsunset.conf written", bool(sun_path and sun_path.is_file()), str(sun_path))
        if sun_path and sun_path.is_file():
            body = sun_path.read_text(encoding="utf-8")
            s.ok("hyprsunset night profile 22:15", "time = 22:15" in body, body[:400])
            s.ok("hyprsunset day profile 6:00", "time = 6:00" in body, body[:400])
            s.ok("hyprsunset night temperature", "temperature = 4000" in body, body[:400])
            s.ok("hyprsunset day identity", "identity = true" in body, body[:400])
            s.ok("hyprsunset night is kelvin not gamma", "gamma = 0.8" not in body, body[:400])
        off_sun = qs.ipc("call", "tanjun", "setSunset", '{"on":false}')
        s.eq("setSunset off exit", off_sun.returncode, 0)
        try:
            after_off = json.loads((off_sun.stdout or "").strip() or "{}")
        except json.JSONDecodeError:
            after_off = {}
        s.eq("setSunset off", after_off.get("on"), False)
        s.eq("setSunset off keeps kelvin", int(after_off.get("nightTemp") or 0), 4000)
        deadline = time.time() + 2
        off_body = ""
        while sun_path and time.time() < deadline:
            if sun_path.is_file():
                off_body = sun_path.read_text(encoding="utf-8")
                if "temperature =" not in off_body and "identity = true" in off_body:
                    break
            time.sleep(0.05)
        s.ok("hyprsunset off is identity", "identity = true" in off_body and "temperature =" not in off_body, off_body[:400])
        on_sun = qs.ipc("call", "tanjun", "setSunset", '{"on":true}')
        s.eq("setSunset on exit", on_sun.returncode, 0)
        try:
            after_on = json.loads((on_sun.stdout or "").strip() or "{}")
        except json.JSONDecodeError:
            after_on = {}
        s.eq("setSunset on again", after_on.get("on"), True)
        deadline = time.time() + 2
        on_body = ""
        while sun_path and time.time() < deadline:
            if sun_path.is_file():
                on_body = sun_path.read_text(encoding="utf-8")
                if "temperature = 4000" in on_body:
                    break
            time.sleep(0.05)
        s.ok("hyprsunset on restores kelvin", "temperature = 4000" in on_body, on_body[:400])

        idle_raw = qs.ipc("call", "tanjun", "idleJson")
        s.eq("idleJson exit", idle_raw.returncode, 0)
        try:
            idle_info = json.loads((idle_raw.stdout or "").strip() or "{}")
            idle_err = ""
        except json.JSONDecodeError as e:
            idle_info = {}
            idle_err = str(e)
        s.ok("idleJson json", isinstance(idle_info, dict) and not idle_err, idle_err or str(idle_info))
        s.eq("idle default dim min", int(idle_info.get("dim") or 0), 2)
        s.eq("idle default lock min", int(idle_info.get("lock") or 0), 5)
        s.eq("idle default dpms min", int(idle_info.get("dpms") or 0), 10)
        s.eq("idle default sleep min", int(idle_info.get("sleep") or 0), 15)
        s.eq("idle default hibernate min", int(idle_info.get("hibernate") or 0), 30)
        s.eq("idle default dim sec", int(idle_info.get("dimSec") or 0), 120)
        s.eq("idle default hibernate sec", int(idle_info.get("hibernateSec") or 0), 1800)
        set_idle = qs.ipc("call", "tanjun", "setIdle", '{"dim":3,"hibernate":45}')
        s.eq("setIdle exit", set_idle.returncode, 0)
        try:
            after_idle = json.loads((set_idle.stdout or "").strip() or "{}")
        except json.JSONDecodeError:
            after_idle = {}
        s.eq("setIdle dim min", int(after_idle.get("dim") or 0), 3)
        s.eq("setIdle hibernate min", int(after_idle.get("hibernate") or 0), 45)
        s.eq("setIdle dim sec", int(after_idle.get("dimSec") or 0), 180)
        s.eq("setIdle hibernate sec", int(after_idle.get("hibernateSec") or 0), 2700)
        s.eq("setIdle keeps sleep", int(after_idle.get("sleep") or 0), 15)
        cfg_idle = json.loads((qs.ipc("call", "tanjun", "configJson").stdout or "").strip() or "{}")
        idle_cfg = cfg_idle.get("idle") if isinstance(cfg_idle, dict) else None
        s.ok("config idle object after set", isinstance(idle_cfg, dict), str(cfg_idle))
        if isinstance(idle_cfg, dict):
            s.eq("config idle dimMin", int(idle_cfg.get("dimMin") or 0), 3)
            s.eq("config idle hibernateMin", int(idle_cfg.get("hibernateMin") or 0), 45)
        qs.ipc("call", "tanjun", "setIdle", '{"dim":2,"hibernate":30}')

        desk_raw = qs.ipc("call", "tanjun", "deskJson")
        s.eq("deskJson exit", desk_raw.returncode, 0)
        try:
            desk = json.loads((desk_raw.stdout or "").strip() or "{}")
            desk_err = ""
        except json.JSONDecodeError as e:
            desk = {}
            desk_err = str(e)
        s.ok("deskJson json", isinstance(desk, dict) and not desk_err, desk_err or str(desk))
        names = desk.get("names") if isinstance(desk, dict) else None
        s.ok("desk names list", isinstance(names, list) and len(names or []) >= 1, str(desk))
        s.ok("desk internal named", bool(desk.get("internal")), str(desk))
        s.ok("desk kind known", desk.get("kind") in ("first", "second", "extend", ""), str(desk))
        if isinstance(names, list) and len(names) >= 2:
            first = qs.ipc("call", "tanjun", "setDesk", "first")
            s.eq("setDesk first exit", first.returncode, 0)
            try:
                after_first = json.loads((first.stdout or "").strip() or "{}")
            except json.JSONDecodeError:
                after_first = {}
            s.eq("setDesk first kind", after_first.get("kind"), "first")
            enabled = after_first.get("enabled") or []
            s.eq("setDesk first only laptop", enabled, [after_first.get("internal")])
            ext = qs.ipc("call", "tanjun", "setDesk", "extend")
            s.eq("setDesk extend exit", ext.returncode, 0)
            try:
                after_ext = json.loads((ext.stdout or "").strip() or "{}")
            except json.JSONDecodeError:
                after_ext = {}
            s.eq("setDesk extend kind", after_ext.get("kind"), "extend")
            s.eq("setDesk extend both on", len(after_ext.get("enabled") or []), 2)
            pin = Path(qs.home) / "config" / "hypr" / "monitors.lua" if qs.home else None
            lua = ""
            deadline = time.time() + 2
            while pin and time.time() < deadline:
                if pin.is_file():
                    lua = pin.read_text(encoding="utf-8")
                    if all(n in lua for n in names[:2]) and "0x0@" not in lua:
                        break
                time.sleep(0.05)
            s.ok("monitors.lua written", bool(pin and pin.is_file()), str(pin))
            if lua or (pin and pin.is_file()):
                lua = lua or pin.read_text(encoding="utf-8")
                s.ok("monitors.lua has both outputs", all(n in lua for n in names[:2]), lua[:400])
                s.ok("monitors.lua no 0x0 mode", "0x0@" not in lua, lua[:400])
            qs.ipc("call", "tanjun", "setDesk", desk.get("kind") or "extend")

        qs.ipc("call", "tanjun", "closeMenus")
        dropped = False
        deadline = time.time() + 1.2
        while time.time() < deadline:
            if not _truthy((qs.ipc("prop", "get", "tanjun", "settingsReady").stdout or "")):
                dropped = True
                break
            time.sleep(0.05)
        s.ok("settings dropped after close", dropped, "settingsReady stayed true")
        after = qs.ipc("prop", "get", "tanjun", "settingsOpen")
        s.ok("settings closed", not _truthy(after.stdout or ""), after.stdout)
        ram_after_settings = _ram()
        s.ok("ram after settings close measured", ram_after_settings["rss"] > 0, _ram_msg(ram_after_settings))
        s.ok("ram after settings close under 280M", ram_after_settings["rss"] <= 286720, _ram_msg(ram_after_settings))
        idle_again = _poll()
        s.ok("host idle after close", idle_again.get("host") is False, str(idle_again))
        s.ok("vpn idle after close", idle_again.get("vpn") is False, str(idle_again))
        s.ok("weather idle after close", idle_again.get("weather") is False, str(idle_again))
        s.ok("mixer idle after close", idle_again.get("mixer") is False, str(idle_again))

        qs.ipc("call", "tanjun", "toggleLauncher")
        launch_mode = {}
        deadline = time.time() + 2
        while time.time() < deadline:
            launch = qs.ipc("prop", "get", "tanjun", "launcherOpen")
            launch_mode = json.loads((qs.ipc("call", "tanjun", "uiMode").stdout or "").strip() or "{}")
            if _truthy(launch.stdout or "") and launch_mode.get("launcherCatchAway") is False:
                break
            time.sleep(0.05)
        s.ok("launcher opened", _truthy((qs.ipc("prop", "get", "tanjun", "launcherOpen").stdout or "")), "")
        s.ok("launcher ready", _truthy((qs.ipc("prop", "get", "tanjun", "launcherReady").stdout or "")), "")
        s.ok("weather live in launcher", _poll().get("weather") is True, str(_poll()))
        s.ok("launcher has no away catcher", launch_mode.get("launcherCatchAway") is False, str(launch_mode))
        qs.ipc("call", "tanjun", "closeMenus")
        time.sleep(0.15)
        launch = qs.ipc("prop", "get", "tanjun", "launcherOpen")
        s.ok("launcher closed", not _truthy(launch.stdout or ""), launch.stdout)
        dropped_launch = False
        deadline = time.time() + 1.2
        while time.time() < deadline:
            if not _truthy((qs.ipc("prop", "get", "tanjun", "launcherReady").stdout or "")):
                dropped_launch = True
                break
            time.sleep(0.05)
        s.ok("launcher dropped after close", dropped_launch, "launcherReady stayed true")
        s.ok("weather idle after launcher close", _poll().get("weather") is False, str(_poll()))
        ram_after_launcher = _ram()
        s.ok("ram after launcher close under 280M", ram_after_launcher["rss"] <= 286720, _ram_msg(ram_after_launcher))

        qs.ipc("call", "tanjun", "toggleSidebar")
        side = {}
        side_mode = {}
        deadline = time.time() + 2
        while time.time() < deadline:
            side_mode = json.loads((qs.ipc("call", "tanjun", "uiMode").stdout or "").strip() or "{}")
            try:
                side = json.loads((qs.ipc("call", "tanjun", "sidebarJson").stdout or "").strip() or "{}")
            except json.JSONDecodeError:
                side = {}
            rest_x = side.get("x")
            if (
                side_mode.get("kind") == "sidebar"
                and side.get("ready") is True
                and int(side.get("w") or 0) >= 280
                and rest_x == 0
            ):
                break
            time.sleep(0.05)
        s.eq("uiMode sidebar kind", side_mode.get("kind"), "sidebar")
        s.ok("system ready", side.get("ready") is True, str(side))
        s.ok("system panel width", int(side.get("w") or 0) >= 280, str(side))
        s.eq("system edge", side.get("edge"), "left")
        s.eq("system from side", int(side.get("fromX") or 0), -int(side.get("w") or 0))
        s.eq("system rest x", side.get("x"), 0)
        opened_walls = qs.ipc("call", "tanjun", "openWalls")
        s.eq("openWalls exit", opened_walls.returncode, 0)
        time.sleep(0.15)
        walls_mode = json.loads((qs.ipc("call", "tanjun", "uiMode").stdout or "").strip() or "{}")
        s.ok("walls picker open", walls_mode.get("wallsOpen") is True, str(walls_mode))
        folded = qs.ipc("call", "tanjun", "setWallFolder", "/tmp")
        s.eq("setWallFolder exit", folded.returncode, 0)
        time.sleep(0.1)
        walls_mode = json.loads((qs.ipc("call", "tanjun", "uiMode").stdout or "").strip() or "{}")
        s.ok("walls folder /tmp", (walls_mode.get("wallFolder") or "").rstrip("/") == "/tmp", str(walls_mode))
        qs.ipc("call", "tanjun", "closeMenus")
        time.sleep(0.15)
        walls_mode = json.loads((qs.ipc("call", "tanjun", "uiMode").stdout or "").strip() or "{}")
        s.ok("walls picker closed", walls_mode.get("wallsOpen") is False, str(walls_mode))

        apps = {}
        deadline = time.time() + 2
        while time.time() < deadline:
            apps_raw = qs.ipc("call", "tanjun", "launcherJson")
            try:
                apps = json.loads((apps_raw.stdout or "").strip() or "{}")
                apps_err = ""
            except json.JSONDecodeError as e:
                apps = {}
                apps_err = str(e)
            if int(apps.get("n") or 0) >= 3 or int(apps.get("count") or 0) >= 3:
                break
            time.sleep(0.1)
        s.eq("launcherJson exit", apps_raw.returncode, 0)
        s.ok("launcherJson json", isinstance(apps, dict) and not apps_err, apps_err or str(apps)[:200])
        app_n = int(apps.get("n") or 0)
        app_count = int(apps.get("count") or app_n)
        s.ok("launcher sees several apps", max(app_n, app_count) >= 3, str(apps))
        s.eq("launcher app keys unique", app_n, int(apps.get("unique") or 0))

        qs.ipc("call", "tanjun", "toggleOverview")
        ov_mode = {}
        deadline = time.time() + 2
        while time.time() < deadline:
            ov_mode = json.loads((qs.ipc("call", "tanjun", "uiMode").stdout or "").strip() or "{}")
            if ov_mode.get("kind") == "overview" and (int(ov_mode.get("overviewCount") or 0) == 0 or ov_mode.get("overviewPick")):
                break
            time.sleep(0.1)
        ov = qs.ipc("prop", "get", "tanjun", "overviewOpen")
        s.ok("overview opened", _truthy(ov.stdout or ""), ov.stdout)
        s.ok("overview ready", _truthy((qs.ipc("prop", "get", "tanjun", "overviewReady").stdout or "")), "")
        s.eq("uiMode overview kind", ov_mode.get("kind"), "overview")
        ov_count = int(ov_mode.get("overviewCount") or 0)
        ov_pick = ov_mode.get("overviewPick") or ""
        s.ok("overview count is int", ov_count >= 0, str(ov_mode))
        s.ok("overview pick when windows exist", ov_count == 0 or bool(ov_pick), str(ov_mode))
        if ov_count >= 2:
            qs.ipc("call", "tanjun", "toggleOverview")
            time.sleep(0.2)
            nudged = json.loads((qs.ipc("call", "tanjun", "uiMode").stdout or "").strip() or "{}")
            s.ok("overview pick moves", (nudged.get("overviewPick") or "") != ov_pick, str(nudged))
        qs.ipc("call", "tanjun", "closeMenus")
        time.sleep(0.15)
        ov = qs.ipc("prop", "get", "tanjun", "overviewOpen")
        s.ok("overview closed", not _truthy(ov.stdout or ""), ov.stdout)
        closed_mode = json.loads((qs.ipc("call", "tanjun", "uiMode").stdout or "").strip() or "{}")
        s.eq("overview pick cleared", closed_mode.get("overviewPick") or "", "")

        before = qs.ipc("prop", "get", "tanjun", "dnd")
        qs.ipc("call", "tanjun", "toggleDnd")
        time.sleep(0.1)
        mid = qs.ipc("prop", "get", "tanjun", "dnd")
        s.ok("dnd flips", _truthy(mid.stdout or "") != _truthy(before.stdout or ""), f"{before.stdout!r} -> {mid.stdout!r}")
        qs.ipc("call", "tanjun", "toggleDnd")
        time.sleep(0.1)
        back = qs.ipc("prop", "get", "tanjun", "dnd")
        s.eq("dnd restored", _truthy(back.stdout or ""), _truthy(before.stdout or ""))

        qs.ipc("call", "tanjun", "closeMenus")
        time.sleep(0.35)
        ram_end = _ram()
        s.ok("ram end measured", ram_end["rss"] > 0, _ram_msg(ram_end))
        s.ok("ram end under 280M", ram_end["rss"] <= 286720, _ram_msg(ram_end))
        s.ok("ram end still software", "libLLVM" not in _maps(), "libLLVM mapped after menus")
        print(
            "qs ram"
            f"  idle={ram_idle['rss']}k/{ram_idle['anon']}k"
            f"  settings={ram_settings['rss']}k"
            f"  closed={ram_after_settings['rss']}k"
            f"  launcher={ram_after_launcher['rss']}k"
            f"  end={ram_end['rss']}k/{ram_end['anon']}k"
        )
    finally:
        try:
            if saved_style:
                qs.ipc("call", "tanjun", "setStyle", saved_style)
        except Exception:
            pass
        try:
            qs.ipc("call", "tanjun", "unlock")
            qs.ipc("call", "tanjun", "closeMenus")
        except Exception:
            pass
        qs.stop()
