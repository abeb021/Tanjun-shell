from __future__ import annotations

from lib import SHELL, has_cyrillic, qml_files, read, tracked_text_files


def register(s) -> None:
    english_roots = []
    from lib import COMP, ROOT, SCRIPTS

    for p in tracked_text_files():
        if ".cursor" in p.parts:
            continue
        text = read(p)
        rel = str(p.relative_to(ROOT))
        s.ok(f"english {rel}", not has_cyrillic(text), "cyrillic in tracked file")
    for p in qml_files():
        text = read(p)
        s.lacks(f"no TODO leftover {p.name}", text, "FIXME")
    screens = read(SHELL / "services" / "Screens.qml")
    s.has("compactMode", screens, "function compactMode")
    s.has("sameMode", screens, "function sameMode")
    s.has("setScale", screens, "function setScale")
    s.has("setMode", screens, "function setMode")
    s.has("setGamma", screens, "function setGamma")
    motion = read(SHELL / "services" / "Motion.qml")
    s.has("motion pop", motion, "pop")
    audio = read(SHELL / "services" / "Audio.qml")
    s.has("audio nudge", audio, "function nudge")
    s.has("audio mute", audio, "function toggleMute")
    net = read(SHELL / "services" / "Net.qml")
    s.has("net vpn", net, "vpn")
    bat = read(SHELL / "services" / "Battery.qml")
    s.has("battery percent", bat, "percent")
    time = read(SHELL / "services" / "Time.qml")
    s.has("time cycle", time, "function cycle")
    launches = read(SHELL / "services" / "Launches.qml")
    s.has("launches bump", launches, "function bump")
    notifs = read(SHELL / "services" / "Notifs.qml")
    s.has("notifs list", notifs, "list")
    media = read(SHELL / "services" / "Media.qml")
    s.has("media player", media, "player")
    host = read(SHELL / "services" / "Host.qml")
    s.has("host cpu", host, "cpu")
    s.has("host ram", host, "ram")
    weather = read(SHELL / "services" / "Weather.qml")
    s.has("weather text", weather, "property string text")
    backlight = read(SHELL / "services" / "Backlight.qml")
    s.has("backlight nudge", backlight, "function nudge")
    s.exists(COMP / "niri" / "config" / "keybinds.kdl")
    s.exists(COMP / "niri" / "config" / "layers.kdl")
    s.exists(COMP / "niri" / "config" / "input.kdl")
    s.exists(COMP / "niri" / "scripts" / "idle.sh")
    s.exists(COMP / "hyprland" / "modules" / "binds.lua")
    s.exists(COMP / "hyprland" / "modules" / "workspace.lua")
    s.exists(SCRIPTS / "install-hypr.sh")
    overview = read(SHELL / "modules" / "overview" / "Overview.qml")
    s.has("overview activateWorkspace", overview, "Compositor.activateWorkspace")
    s.has("overview focusWindow", overview, "Compositor.focusWindow")
    s.has("overview compositor windows", overview, "Compositor.windows")
    s.has("niri idle in shell", read(SHELL / "services" / "Idle.qml"), "IdleMonitor")
