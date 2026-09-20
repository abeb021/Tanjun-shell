from __future__ import annotations

import json
import os
import time

from lib import QS_BIN, Qs


def _truthy(text: str) -> bool:
    return text.strip().lower() in ("true", "1")


def register(s) -> None:
    s.ok("qs on PATH", bool(QS_BIN), "qs not on PATH")
    s.ok("wayland display", bool(os.environ.get("WAYLAND_DISPLAY")), "WAYLAND_DISPLAY unset")
    if not QS_BIN or not os.environ.get("WAYLAND_DISPLAY"):
        return

    qs = Qs()
    err = qs.start()
    saved_style = None
    try:
        s.ok("qs running", not err, (err or qs.log)[-800:])
        if err:
            return
        s.ok("qs owned instance", qs.owned, "harness must not attach to live shell")
        s.ok("qs configuration loaded", "Configuration Loaded" in (qs.log or ""), (qs.log or "")[-400:])

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
            "styles",
            "styleJson",
            "pollJson",
            "hostCaps",
            "settingsCatalog",
            "uiMode",
            "toggleOverview",
        ):
            s.ok(f"ipc has {fn}", f"function {fn}" in out, out[-400:])

        ping = qs.ipc("call", "tanjun", "ping")
        s.eq("ping exit", ping.returncode, 0)
        s.eq("ping", (ping.stdout or "").strip(), "ok")

        qs.ipc("call", "tanjun", "closeMenus")
        time.sleep(0.2)
        ready = qs.ipc("prop", "get", "tanjun", "settingsReady")
        s.ok("settings not preloaded", not _truthy(ready.stdout or ""), ready.stdout)

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
        s.eq("uiMode idle overview pick", mode.get("overviewPick") or "", "")
        s.eq("uiMode idle overview count", int(mode.get("overviewCount") or 0), 0)

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
        for title in ("system", "sound", "type", "From wall", "Monochrome"):
            s.ok(f"catalog has {title}", title in titles, str(titles[:20]))

        qs.ipc("call", "tanjun", "closeMenus")
        time.sleep(0.15)
        closed = qs.ipc("prop", "get", "tanjun", "settingsOpen")
        s.ok("settings closed before toggle", not _truthy(closed.stdout or ""), closed.stdout)

        opened = qs.ipc("call", "tanjun", "toggleSettings")
        s.eq("toggleSettings exit", opened.returncode, 0)
        time.sleep(0.25)
        now = qs.ipc("prop", "get", "tanjun", "settingsOpen")
        s.ok("settings opened", _truthy(now.stdout or ""), now.stdout)
        s.ok("settings ready after toggle", _truthy((qs.ipc("prop", "get", "tanjun", "settingsReady").stdout or "")), "")
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
        for pid in ("system", "sound", "screen", "network", "bluetooth", "type", "clock", "weather", "devices", "style", "color"):
            s.ok(f"settings has {pid}", pid in pages, str(pages))
        s.ok("settings has no session", "session" not in pages, str(pages))
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
        s.eq("settings rail count", rail_n, "11")
        try:
            rail_h = int((qs.ipc("prop", "get", "tanjun", "settingsRailH").stdout or "0").strip())
        except ValueError:
            rail_h = 0
        s.ok("settings rail visible", rail_h >= 200, f"height {rail_h}")
        for pid in ("network", "bluetooth", "screen", "type", "clock", "weather", "devices", "style", "color"):
            qs.ipc("call", "tanjun", "openSettingsPage", pid)
            time.sleep(0.12)
            s.eq(
                f"settings page {pid}",
                (qs.ipc("prop", "get", "tanjun", "settingsPage").stdout or "").strip(),
                pid,
            )
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
        for sid in ("tanjun", "panel"):
            s.ok(f"style has {sid}", sid in style_keys, str(style_keys))
        prior_style = (qs.ipc("prop", "get", "tanjun", "style").stdout or "").strip()
        saved_style = prior_style or "panel"
        prior_theme = json.loads((qs.ipc("call", "tanjun", "themeJson").stdout or "").strip() or "{}")
        other = "tanjun" if prior_style != "tanjun" else "panel"
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
        s.eq("styleJson tick", chrome.get("tick"), other == "panel")
        s.eq("styleJson tickPops", chrome.get("tickPops"), False)
        s.eq("styleJson chipBorder", chrome.get("chipBorder"), 1 if other == "panel" else 0)
        s.eq("styleJson pip", chrome.get("pip"), other == "panel")
        s.ok("themeJson has no tick", "tick" not in after_theme, str(after_theme.keys()))
        s.ok("themeJson has no chipBorder", "chipBorder" not in after_theme, str(after_theme.keys()))
        cfg_style = json.loads((qs.ipc("call", "tanjun", "configJson").stdout or "").strip() or "{}")
        ap = cfg_style.get("appearance") if isinstance(cfg_style, dict) else None
        if other == "panel":
            s.ok(
                "default style omitted from config",
                not isinstance(ap, dict) or ap.get("style") in (None, "", "panel"),
                str(ap),
            )
        else:
            s.eq("config appearance.style", (ap or {}).get("style"), other)
        qs.ipc("call", "tanjun", "setStyle", prior_style or "panel")
        time.sleep(0.1)
        s.eq(
            "style restored",
            (qs.ipc("prop", "get", "tanjun", "style").stdout or "").strip(),
            prior_style or "panel",
        )

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
        idle_again = _poll()
        s.ok("host idle after close", idle_again.get("host") is False, str(idle_again))
        s.ok("vpn idle after close", idle_again.get("vpn") is False, str(idle_again))
        s.ok("weather idle after close", idle_again.get("weather") is False, str(idle_again))
        s.ok("mixer idle after close", idle_again.get("mixer") is False, str(idle_again))

        qs.ipc("call", "tanjun", "toggleLauncher")
        time.sleep(0.2)
        launch = qs.ipc("prop", "get", "tanjun", "launcherOpen")
        s.ok("launcher opened", _truthy(launch.stdout or ""), launch.stdout)
        s.ok("launcher ready", _truthy((qs.ipc("prop", "get", "tanjun", "launcherReady").stdout or "")), "")
        s.ok("weather live in launcher", _poll().get("weather") is True, str(_poll()))
        qs.ipc("call", "tanjun", "closeMenus")
        time.sleep(0.15)
        launch = qs.ipc("prop", "get", "tanjun", "launcherOpen")
        s.ok("launcher closed", not _truthy(launch.stdout or ""), launch.stdout)
        s.ok("launcher stays ready", _truthy((qs.ipc("prop", "get", "tanjun", "launcherReady").stdout or "")), "")
        s.ok("weather idle after launcher close", _poll().get("weather") is False, str(_poll()))

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
    finally:
        try:
            if saved_style:
                qs.ipc("call", "tanjun", "setStyle", saved_style)
        except Exception:
            pass
        try:
            qs.ipc("call", "tanjun", "closeMenus")
        except Exception:
            pass
        qs.stop()
