from __future__ import annotations

from lib import IPC, ROOT, SHELL, read


def register(s) -> None:
    ipc = read(SHELL / "shell.qml")
    s.has("ipc target tanjun", ipc, 'target: "tanjun"')
    s.has("shell Bar", ipc, "Bar {}")
    s.has("shell Osd", ipc, "Osd {}")
    s.has("shell Toasts", ipc, "Toasts {}")
    s.has("shell SessionLock", ipc, "SessionLock {}")
    s.has("shell Launcher lazy", ipc, "Launcher {}")
    s.has("shell Clipboard lazy", ipc, "Clipboard {}")
    s.has("shell Overview lazy", ipc, "Overview {}")
    s.has("shell Settings lazy", ipc, "Settings {}")
    for name in IPC:
        s.has(f"ipc {name}", ipc, f"function {name}")
    s.has("ipc lock", ipc, "function lock")
    s.has("ipc closeMenus", ipc, "function closeMenus")
    s.has("ipc confirmOverview", ipc, "function confirmOverview")

    niri = read(ROOT / "compositors" / "niri" / "config" / "keybinds.kdl")
    hypr = read(ROOT / "compositors" / "hyprland" / "modules" / "binds.lua")
    for name in (
        "toggleLauncher",
        "toggleClipboard",
        "toggleAudio",
        "toggleNetwork",
        "toggleCalendar",
        "toggleBattery",
        "toggleNotify",
        "toggleSidebar",
        "toggleSettings",
        "toggleDnd",
        "lock",
    ):
        s.has(f"niri bind {name}", niri, name)
        s.has(f"hypr bind {name}", hypr, name)
    s.has("niri any-display", niri, "--any-display")
    s.has("niri Mod+A launcher", niri, "Mod+A")
    s.has("niri Mod+V clipboard", niri, "Mod+V")
    s.has("niri Mod+L lock", niri, "Mod+L")
    s.has("hypr Super+A", hypr, "mainMod .. \" + A\"")
    s.has("hypr Super+V", hypr, "mainMod .. \" + V\"")
    s.has("hypr Super+L", hypr, "mainMod .. \" + L\"")
    for i in range(1, 11):
        s.has(f"niri desk {i}", niri, f"focus-workspace {i}")
        s.has(f"niri move desk {i}", niri, f"move-window-to-workspace {i}")
    s.has("hypr desks 1..10", hypr, "for i = 1, 10 do")
    s.has("hypr desk focus lua", hypr, "hl.dsp.focus({ workspace = i })")
    s.has("hypr desk move lua", hypr, "hl.dsp.window.move({ workspace = i })")
    s.has("readme ipc launcher", read(ROOT / "README.md"), "toggleLauncher")
    shots = read(ROOT / "scripts" / "shots.sh")
    s.has("shots ipc path", shots, "call tanjun")
