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
        ):
            s.ok(f"ipc has {fn}", f"function {fn}" in out, out[-400:])

        ping = qs.ipc("call", "tanjun", "ping")
        s.eq("ping exit", ping.returncode, 0)
        s.eq("ping", (ping.stdout or "").strip(), "ok")

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

        cfg_raw = qs.ipc("call", "tanjun", "configJson")
        s.eq("configJson exit", cfg_raw.returncode, 0)
        try:
            cfg = json.loads((cfg_raw.stdout or "").strip() or "{}")
            cfg_err = ""
        except json.JSONDecodeError as e:
            cfg = None
            cfg_err = str(e)
        s.ok("configJson json", isinstance(cfg, dict) and not cfg_err, cfg_err or (cfg_raw.stdout or "")[:200])

        qs.ipc("call", "tanjun", "closeMenus")
        time.sleep(0.15)
        closed = qs.ipc("prop", "get", "tanjun", "settingsOpen")
        s.ok("settings closed before toggle", not _truthy(closed.stdout or ""), closed.stdout)

        opened = qs.ipc("call", "tanjun", "toggleSettings")
        s.eq("toggleSettings exit", opened.returncode, 0)
        time.sleep(0.2)
        now = qs.ipc("prop", "get", "tanjun", "settingsOpen")
        s.ok("settings opened", _truthy(now.stdout or ""), now.stdout)
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
        time.sleep(0.15)
        after = qs.ipc("prop", "get", "tanjun", "settingsOpen")
        s.ok("settings closed", not _truthy(after.stdout or ""), after.stdout)

        qs.ipc("call", "tanjun", "toggleLauncher")
        time.sleep(0.2)
        launch = qs.ipc("prop", "get", "tanjun", "launcherOpen")
        s.ok("launcher opened", _truthy(launch.stdout or ""), launch.stdout)
        qs.ipc("call", "tanjun", "closeMenus")
        time.sleep(0.15)
        launch = qs.ipc("prop", "get", "tanjun", "launcherOpen")
        s.ok("launcher closed", not _truthy(launch.stdout or ""), launch.stdout)

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
