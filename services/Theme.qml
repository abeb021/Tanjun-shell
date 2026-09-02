pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string kind: "dark"
    property string name: "monochrome"
    property string label: "Monochrome"

    property color accent: "#e0e0e0"
    property color accentHover: "#f0f0f0"
    property color critical: "#ef4444"
    property color warning: "#eab308"
    property color info: "#808080"
    property color good: "#7bc379"
    property color fg: "#d4d4d4"
    property color fgSub: "#9ca3af"
    property color bg: "#1b1b1f"
    property color surface: "#252525"
    property color surfaceHover: "#2e2e36"

    readonly property int radius: 1
    readonly property int barHeight: 28
    readonly property int fontPx: 13
    readonly property string fontUi: "JetBrains Mono"
    readonly property string fontJp: "Noto Sans CJK JP"
    readonly property string fontIcons: "Symbols Nerd Font"

    readonly property var catalog: [
        { kind: "dark", name: "monochrome", label: "Monochrome" },
        { kind: "dark", name: "obsidian", label: "Obsidian" },
        { kind: "dark", name: "gray", label: "Gray" },
        { kind: "dark", name: "deepblue", label: "Deep Blue" },
        { kind: "dark", name: "emerald", label: "Emerald" },
        { kind: "dark", name: "goldenamber", label: "Golden Amber" },
        { kind: "dark", name: "fierysunset", label: "Fiery Sunset" },
        { kind: "dark", name: "rosepink", label: "Rose Pink" },
        { kind: "white", name: "mocha", label: "Mocha" },
        { kind: "white", name: "macchiato", label: "Macchiato" }
    ]

    function apply(obj) {
        if (!obj)
            return;
        kind = obj.kind ?? kind;
        name = obj.name ?? name;
        label = obj.label ?? name;
        accent = obj.accent ?? accent;
        accentHover = obj.accentHover ?? accentHover;
        critical = obj.critical ?? critical;
        warning = obj.warning ?? warning;
        info = obj.info ?? info;
        good = obj.good ?? good;
        fg = obj.fg ?? fg;
        fgSub = obj.fgSub ?? fgSub;
        bg = obj.bg ?? bg;
        surface = obj.surface ?? surface;
        surfaceHover = obj.surfaceHover ?? surfaceHover;
    }

    function loadPalette(nextKind, nextName) {
        kind = nextKind;
        name = nextName;
        paletteFile.path = `${Quickshell.shellDir}/themes/${nextKind}/${nextName}.json`;
        paletteFile.reload();
    }

    function setTheme(nextKind, nextName) {
        loadPalette(nextKind, nextName);
        stateFile.setText(JSON.stringify({ kind: nextKind, name: nextName }));
        const switcher = `${Quickshell.env("HOME")}/.config/waybar/scripts/theme-switcher.sh`;
        Quickshell.execDetached(["bash", switcher, nextName]);
    }

    FileView {
        id: stateFile
        path: `${Quickshell.env("HOME")}/.config/tanjun/state.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const s = JSON.parse(text());
                if (s.kind && s.name)
                    root.loadPalette(s.kind, s.name);
            } catch (e) {}
        }
    }

    FileView {
        id: paletteFile
        path: `${Quickshell.shellDir}/themes/dark/monochrome.json`
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.apply(JSON.parse(text()));
            } catch (e) {}
        }
        Component.onCompleted: {
            try {
                root.apply(JSON.parse(text()));
            } catch (e) {}
        }
    }
}
