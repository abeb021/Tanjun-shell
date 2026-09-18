from __future__ import annotations

from lib import ROOT, SHELL, read


def register(s) -> None:
    cfg = read(SHELL / "services" / "Config.qml")
    s.has("config.json path", cfg, "config.json")
    s.has("state.json path", cfg, "state.json")
    s.has("writeSparse", cfg, "function writeSparse")
    s.has("omit default", cfg, "sparseObject")
    s.has("clock zones", cfg, "clock.zones")
    s.has("weatherCity", cfg, "weatherCity")
    s.has("screens.gamma", cfg, "screens.gamma")
    s.has("fontUi pin", cfg, "appearance.fontUi")
    s.has("JsonAdapter", cfg, "JsonAdapter")
    todo = read(ROOT / "TODO.md")
    s.has("todo current version", todo, "Current:")
    s.ok("todo vMAJOR.MINOR", "Current: **" in todo)
    lock = read(SHELL / "modules" / "lock" / "LockSurface.qml")
    sess = read(SHELL / "modules" / "lock" / "SessionLock.qml")
    s.has("lock password", lock, "TextInput")
    s.has("lock clock", lock, "Time.formatTime")
    s.has("lock wallpaper", lock, "Theme.wallFile")
    s.has("session lock", sess, "SessionLock")
    ls = read(SHELL / "services" / "Lock.qml")
    s.has("lock request", ls, "function request")
    s.has("lock ipc", read(SHELL / "shell.qml"), "Lock.request")
    state = read(SHELL / "services" / "ShellState.qml")
    for fn in (
        "togglePopout",
        "closePopout",
        "closeMenus",
        "toggleSidebar",
        "toggleLauncher",
        "toggleClipboard",
        "toggleSettings",
        "toggleOverview",
        "openTray",
    ):
        s.has(f"state {fn}", state, f"function {fn}")
    s.has("state dnd", state, "property bool dnd")
    s.lacks("close menus no parkFocus", state, "parkFocus")
    s.lacks("close menus no desk bounce", state, "keepDeskIfMoved")
    s.lacks("close menus no noteDesk", state, "noteDesk")
    s.lacks("close menus no stayDesk", state, "stayDesk")
    pop = read(SHELL / "modules" / "popouts" / "BarPop.qml")
    s.has("popout Escape", pop, "Escape")
    s.has("popout click-away", pop, "ShellState.closeMenus()")
    s.has("popout key prime", pop, "KeyPrime")
    s.has("popout bar hole", pop, "Intersection.Xor")
    s.has("popout bar strip", pop, "Theme.barHeight")
    s.has("popout this screen", pop, "popoutScreen")
    s.has("popout other output", pop, "tanjun-pop-away")
    s.has("state popout screen from focus", state, "Compositor.focusedOutput")
    s.has("state sidebar screen from focus", state, "sidebarScreen = Compositor.focusedOutput")
    s.exists(SHELL / "modules" / "osd" / "Osd.qml")
    s.exists(SHELL / "modules" / "notifs" / "Toasts.qml")
    s.exists(SHELL / "modules" / "clipboard" / "Clipboard.qml")
    s.exists(SHELL / "modules" / "overview" / "Overview.qml")
    s.exists(SHELL / "modules" / "sidebar" / "Sidebar.qml")
    paint = SHELL / "scripts" / "tanjun-paint.py"
    s.exists(paint)
    ptxt = read(paint)
    s.has("paint kitty", ptxt, "paint_kitty")
    s.has("paint niri skip hypr", ptxt, "on_niri")
    s.has("paint hex", ptxt, "def parse_rgb")
    s.exists(SHELL / "scripts" / "tanjun-host.py")
    s.exists(SHELL / "scripts" / "clip-decode.sh")
    s.exists(ROOT / "scripts" / "setup.sh")
    s.exists(ROOT / "scripts" / "bluetooth.sh")
    setup = read(ROOT / "scripts" / "setup.sh")
    s.has("setup --hyprland", setup, "--hyprland")
    s.has("setup --niri", setup, "--niri")
    s.has("setup quickshell link", setup, "quickshell")
    s.has("niri autostart quickshell", read(ROOT / "compositors" / "niri" / "config" / "autostart.kdl"), "quickshell")
    auto = read(ROOT / "compositors" / "hyprland" / "modules" / "autostart.lua")
    s.has("hypr spawn quickshell", auto, "quickshell")
    s.has("osd Audio", read(SHELL / "modules" / "osd" / "Osd.qml"), "Audio")
    side = read(SHELL / "modules" / "sidebar" / "Sidebar.qml")
    s.has("sidebar lock", side, "Lock.request")
    s.has("sidebar exit", side, "Compositor.exitSession")
    s.has("sidebar key prime", side, "KeyPrime")
    s.has("sidebar this screen", side, "sidebarScreen")
    s.has("sidebar bar hole", side, "Intersection.Xor")
    launch = read(SHELL / "modules" / "launcher" / "Launcher.qml")
    s.has("launcher bar hole", launch, "Intersection.Xor")
    s.has("clipboard cliphist", read(SHELL / "modules" / "clipboard" / "Clipboard.qml"), "cliphist")
    s.has("clipboard overlay host", read(SHELL / "modules" / "clipboard" / "Clipboard.qml"), "OverlayHost")
    s.has("overview overlay host", read(SHELL / "modules" / "overview" / "Overview.qml"), "OverlayHost")
