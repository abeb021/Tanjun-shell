from __future__ import annotations

from lib import COMP, ROOT, SHELL, read


def register(s) -> None:
    paint = read(SHELL / "scripts" / "tanjun-paint.py")
    pick = read(SHELL / "modules" / "sidebar" / "WallPick.qml")
    theme = read(SHELL / "services" / "Theme.qml")
    lock = read(SHELL / "services" / "Lock.qml")
    surface = read(SHELL / "modules" / "lock" / "LockSurface.qml")
    setup = read(ROOT / "scripts" / "setup.sh")
    hypr = read(COMP / "hyprland" / "modules" / "autostart.lua")
    niri = read(COMP / "niri" / "config" / "autostart.kdl")
    layers = read(COMP / "niri" / "config" / "layers.kdl")

    s.has("paint video exts", paint, "mp4")
    s.has("paint webm", paint, "webm")
    s.has("paint is_video", paint, "def is_video")
    s.has("paint still extract", paint, "ffmpeg")
    s.has("paint mpvpaper", paint, "mpvpaper")
    s.has("paint mpvpaper which", paint, "shutil.which")
    s.has("paint mute loop", paint, "no-audio")
    s.has("paint loop file", paint, "loop-file")
    s.has("paint restore", paint, "def cmd_restore")
    s.has("paint pin wall", paint, "def pin_wall")
    s.has("paint stop video", paint, '_kill("mpvpaper")')
    s.has("paint wallStill", paint, "wallStill")

    s.has("picker mp4", pick, "*.mp4")
    s.has("picker webm", pick, "*.webm")
    s.has("picker video tile", pick, "isVideo")
    s.has("picker empty", pick, '"empty"')

    s.has("theme wallStill", theme, "property string wallStill")
    s.has("lock pause video", lock, "-STOP")
    s.has("lock resume video", lock, "-CONT")
    s.has("lock still wall", surface, "Theme.wallStill")

    s.has("setup mpvpaper", setup, "mpvpaper")
    s.has("setup ffmpeg", setup, "ffmpeg")
    s.has("hypr restore wall", hypr, "tanjun-paint.py")
    s.has("hypr restore cmd", hypr, "restore")
    s.has("niri restore wall", niri, "tanjun-paint.py")
    s.has("niri restore cmd", niri, "restore")
    s.has("niri mpvpaper layer", layers, "mpvpaper")

    cfg = read(SHELL / "services" / "Config.qml")
    side = read(SHELL / "modules" / "sidebar" / "Sidebar.qml")
    s.has("config sampleWall", cfg, "sampleWall")
    s.has("sparse sampleWall", cfg, "theme.sampleWall")
    s.has("paint wall only", paint, "def cmd_wall")
    s.has("theme applyWallMedia", theme, "function applyWallMedia")
    s.has("theme set wall or set", theme, 'Config.theme.sampleWall ? "set" : "wall"')
    s.has("sidebar colors keep", side, "colors · keep")
    s.has("picker colors keep", pick, "colors · keep")
