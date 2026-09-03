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

    readonly property var presets: [
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

    readonly property bool fromWall: name === "wall"
    property string wallFile: ""
    property string wallPick: ""

    readonly property string wallDir: `${Config.configHome}/hypr/assets/wallpapers`
    readonly property url wallFolder: Qt.url("file://" + wallDir)

    function hexOf(c) {
        const s = `${c}`;
        if (s.startsWith("#") && s.length >= 7)
            return `#${s.slice(-6)}`;
        return s;
    }

    function snapshot() {
        return {
            kind: kind,
            name: name,
            label: label,
            accent: hexOf(accent),
            accentHover: hexOf(accentHover),
            critical: hexOf(critical),
            warning: hexOf(warning),
            info: hexOf(info),
            good: hexOf(good),
            fg: hexOf(fg),
            fgSub: hexOf(fgSub),
            bg: hexOf(bg),
            surface: hexOf(surface),
            surfaceHover: hexOf(surfaceHover)
        };
    }

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
        if (nextName === "wall")
            return;
        kind = nextKind;
        name = nextName;
        paletteFile.path = `${Quickshell.shellDir}/themes/${nextKind}/${nextName}.json`;
        paletteFile.reload();
    }

    function persist(nextKind, nextName) {
        Config.ensureStateDir();
        stateFile.path = Config.stateFile;
        const k = nextKind || kind;
        const n = nextName || name;
        const o = n === "wall" ? snapshot() : { kind: k, name: n };
        if (n === "wall") {
            o.kind = "wall";
            o.name = "wall";
            o.label = "From wall";
            if (wallFile.length)
                o.wall = wallFile;
        }
        stateFile.setText(JSON.stringify(o));
    }

    function paint(nextKind, nextName) {
        const n = nextName || name;
        if (n === "wall")
            return;
        Quickshell.execDetached(["python3", `${Quickshell.shellDir}/scripts/tanjun-paint.py`, nextKind || kind, n]);
    }

    function applyWallJson(d) {
        if (!d || !d.accent)
            return;
        d.kind = "wall";
        d.name = "wall";
        d.label = "From wall";
        if (d.wall)
            wallFile = d.wall;
        apply(d);
        persist("wall", "wall");
    }

    function urlPath(u) {
        let s = `${u}`;
        if (s.startsWith("file://")) {
            s = decodeURIComponent(s.slice(7));
            if (s.startsWith("localhost"))
                s = s.slice("localhost".length);
        }
        return s;
    }

    function setWallpaper(path) {
        const p = urlPath(path);
        if (!p.length)
            return;
        wallPick = p;
        setProc.running = false;
        Qt.callLater(() => {
            setProc.running = true;
        });
    }

    function setTheme(nextKind, nextName) {
        if (nextName === "wall") {
            sampleWall();
            return;
        }
        loadPalette(nextKind, nextName);
        persist(nextKind, nextName);
        paint(nextKind, nextName);
    }

    function sampleWall() {
        sampleProc.running = false;
        Qt.callLater(() => {
            sampleProc.running = true;
        });
    }

    Process {
        id: sampleProc
        command: ["python3", `${Quickshell.shellDir}/scripts/tanjun-paint.py`, "sample"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    root.applyWallJson(JSON.parse(text));
                } catch (e) {}
            }
        }
    }

    Process {
        id: setProc
        command: ["python3", `${Quickshell.shellDir}/scripts/tanjun-paint.py`, "set", root.wallPick]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    root.applyWallJson(JSON.parse(text));
                } catch (e) {}
            }
        }
    }

    FileView {
        id: stateFile
        path: Config.stateFile
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const s = JSON.parse(text());
                if (s.name === "wall") {
                    if (s.wall)
                        root.wallFile = s.wall;
                    root.apply(s);
                    return;
                }
                if (s.kind && s.name)
                    root.loadPalette(s.kind, s.name);
            } catch (e) {}
        }
        onLoadFailed: {
            if (path === Config.stateFile)
                path = Config.legacyStateFile;
        }
    }

    FileView {
        id: paletteFile
        path: `${Quickshell.shellDir}/themes/dark/monochrome.json`
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (root.name === "wall")
                return;
            try {
                root.apply(JSON.parse(text()));
            } catch (e) {}
        }
        Component.onCompleted: {
            if (root.name === "wall")
                return;
            try {
                root.apply(JSON.parse(text()));
            } catch (e) {}
        }
    }
}
