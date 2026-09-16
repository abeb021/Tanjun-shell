from __future__ import annotations

from lib import COMP, FORBIDDEN, HOST_FUNCS, HOST_PROPS, ROOT, SHELL, qml_files, read, tracked_text_files


def register(s) -> None:
    face = SHELL / "modules"
    for p in qml_files():
        text = read(p)
        rel = str(p.relative_to(ROOT))
        if p.is_relative_to(face):
            s.lacks(f"face no isNiri {rel}", text, "isNiri")
            s.lacks(f"face no isHypr {rel}", text, "isHypr")
            s.lacks(f"face no NIRI_SOCKET {rel}", text, "NIRI_SOCKET")
            s.lacks(f"face no HYPRLAND_INSTANCE {rel}", text, "HYPRLAND_INSTANCE_SIGNATURE")
        s.lacks(f"no isNiri leak {rel}", text, "Compositor.isNiri")
        s.lacks(f"no isHypr leak {rel}", text, "Compositor.isHypr")

    for name in FORBIDDEN:
        for p in tracked_text_files():
            if ".cursor" in p.parts or "tests" in p.parts:
                continue
            s.lacks(f"voice {p.relative_to(ROOT)} {name}", read(p), name)

    comp = read(SHELL / "services" / "Compositor.qml")
    s.lacks("compositor hides isNiri", comp, "isNiri")
    s.lacks("compositor hides isHypr", comp, "isHypr")
    s.has("compositor host", comp, "readonly property var host")
    s.has("compositor HyprHost", comp, "HyprHost")
    s.has("compositor NiriHost", comp, "NiriHost")
    for fn in HOST_FUNCS:
        s.has(f"compositor fn {fn}", comp, f"function {fn}")
        s.has(f"compositor delegates {fn}", comp, f"host.{fn}")
    for prop in (
        "focusedWorkspaceId",
        "occupied",
        "focusedOutput",
        "layoutName",
        "hasGamma",
        "grabFocus",
        "screenNote",
        "monitorQuery",
        "gammaQuery",
    ):
        s.has(f"compositor prop {prop}", comp, prop)

    for host_name in ("HyprHost.qml", "NiriHost.qml"):
        hp = SHELL / "services" / "comp" / host_name
        s.exists(hp)
        text = read(hp)
        s.has(f"{host_name} is Item", text, "Item {")
        s.lacks(f"{host_name} not QtObject root", text.split("{", 1)[0], "QtObject")
        for fn in HOST_FUNCS:
            s.has(f"{host_name} {fn}", text, f"function {fn}")
        for prop in HOST_PROPS:
            s.has(f"{host_name} {prop}", text, prop)
        s.has(f"{host_name} applied", text, "signal applied")

    hypr = read(SHELL / "services" / "comp" / "HyprHost.qml")
    niri = read(SHELL / "services" / "comp" / "NiriHost.qml")
    s.has("hypr lua focus", hypr, "hl.dsp.focus({ workspace =")
    s.has("hypr lua move", hypr, "hl.dsp.window.move({ workspace =")
    s.has("hypr usingLua", hypr, "Hyprland.usingLua")
    s.has("niri focus-workspace", niri, "focus-workspace")
    s.has("niri event-stream", niri, "event-stream")
    s.eq("hypr hasGamma", "hasGamma: true" in hypr, True)
    s.eq("niri hasGamma", "hasGamma: false" in niri, True)
    s.eq("hypr grabFocus", "grabFocus: true" in hypr, True)
    s.eq("niri grabFocus", "grabFocus: false" in niri, True)
    s.has("hypr live", hypr, "property bool live")
    s.has("niri live", niri, "property bool live")
    s.has("niri live from socket", comp, "NIRI_SOCKET")
    s.has("layout import Quickshell", read(SHELL / "services" / "Layout.qml"), "import Quickshell")
    s.has("layout keymap from host", read(SHELL / "services" / "Layout.qml"), "Compositor.layoutName")
    s.lacks("layout no isNiri", read(SHELL / "services" / "Layout.qml"), "isNiri")
    s.lacks("screens no isNiri", read(SHELL / "services" / "Screens.qml"), "isNiri")
    s.lacks("screens no isHypr", read(SHELL / "services" / "Screens.qml"), "isHypr")
    s.has("screens parseMonitors", read(SHELL / "services" / "Screens.qml"), "Compositor.parseMonitors")
    s.has("screens persistMonitors", read(SHELL / "services" / "Screens.qml"), "Compositor.persistMonitors")
    s.has("screens hasGamma", read(SHELL / "services" / "Screens.qml"), "Compositor.hasGamma")
    s.has("screen page note", read(SHELL / "modules" / "settings" / "ScreenPage.qml"), "Compositor.screenNote")
    s.has("screen page gamma cap", read(SHELL / "modules" / "settings" / "ScreenPage.qml"), "Compositor.hasGamma")
    s.has("settings grabFocus", read(SHELL / "modules" / "settings" / "Settings.qml"), "Compositor.grabFocus")
    s.lacks("screen page no isNiri", read(SHELL / "modules" / "settings" / "ScreenPage.qml"), "isNiri")
    s.exists(COMP / "hyprland" / "hyprland.lua")
    s.exists(COMP / "niri" / "config.kdl")
