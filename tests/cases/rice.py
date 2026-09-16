from __future__ import annotations

import json

from lib import PALETTE_KEYS, SHELL, read


def register(s) -> None:
    theme = read(SHELL / "services" / "Theme.qml")
    s.has("radius 1", theme, "readonly property int radius: 1")
    s.has("barHeight 28", theme, "readonly property int barHeight: 28")
    s.has("default JetBrains", read(SHELL / "services" / "Config.qml"), 'defaultFontUi: "JetBrains Mono"')
    s.has("default JP", read(SHELL / "services" / "Config.qml"), "Noto Sans CJK JP")
    s.has("default icons", read(SHELL / "services" / "Config.qml"), "Symbols Nerd Font")
    s.has("presets list", theme, "readonly property var presets")

    names = []
    for p in sorted((SHELL / "themes").rglob("*.json")):
        s.exists(p)
        data = json.loads(read(p))
        names.append(data.get("name"))
        for key in PALETTE_KEYS:
            s.ok(f"palette {p.stem}.{key}", key in data, f"missing {key}")
        kind = p.parent.name
        s.eq(f"palette {p.stem} kind folder", data.get("kind"), kind)
        s.eq(f"palette {p.stem} name file", data.get("name"), p.stem)
        for key in ("accent", "bg", "fg", "surface"):
            val = str(data.get(key, ""))
            s.ok(f"palette {p.stem}.{key} hex", val.startswith("#") and len(val) in (4, 7, 9), val)
        s.has(f"Theme presets {p.stem}", theme, f'name: "{p.stem}"')
    s.eq("nine palettes plus mocha macchiato", len(names), 10)
    s.ok("monochrome present", "monochrome" in names)
    s.ok("obsidian present", "obsidian" in names)
    s.ok("mocha present", "mocha" in names)
    s.ok("macchiato present", "macchiato" in names)

    hypr = read((SHELL.parent / "compositors" / "hyprland" / "modules" / "general.lua"))
    s.has("gaps_in 0", hypr, "gaps_in = 0")
    s.has("gaps_out 0", hypr, "gaps_out = 0")
    deco = read((SHELL.parent / "compositors" / "hyprland" / "modules" / "decoration.lua"))
    s.has("rounding 1", deco, "rounding = 1")
    niri = read((SHELL.parent / "compositors" / "niri" / "config" / "layout.kdl"))
    s.has("niri gaps 0", niri, "gaps 0")
    s.has("niri focus-ring off", niri, "off")
    s.has("niri border 2", niri, "width 2")
