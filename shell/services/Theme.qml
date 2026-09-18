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
    readonly property int fontPx: Config.appearance.fontPx > 0 ? Config.appearance.fontPx : Config.defaultFontPx
    readonly property string fontUi: Config.appearance.fontUi.length ? Config.appearance.fontUi : Config.defaultFontUi
    readonly property string fontJp: Config.appearance.fontJp.length ? Config.appearance.fontJp : Config.defaultFontJp
    readonly property string fontIcons: Config.appearance.fontIcons.length ? Config.appearance.fontIcons : Config.defaultFontIcons

    readonly property color hairline: Qt.rgba(fg.r, fg.g, fg.b, 0.16)
    readonly property int typeCaption: Math.max(10, fontPx - 2)
    readonly property int typeBody: fontPx
    readonly property int typeTitle: fontPx + 3
    readonly property int typeDisplay: Math.round(fontPx * 4)
    readonly property int typeSeal: fontPx + 5
    readonly property int pad: 14
    readonly property int gap: 8

    readonly property var presets: [
        { kind: "dark", name: "monochrome", label: "Monochrome", bg: "#1b1b1f", surface: "#252525", fg: "#d4d4d4", accent: "#e0e0e0" },
        { kind: "dark", name: "obsidian", label: "Obsidian", bg: "#1b1b1f", surface: "#252525", fg: "#d4d4d4", accent: "#8b5cf6" },
        { kind: "dark", name: "gray", label: "Gray", bg: "#1b1b1f", surface: "#252525", fg: "#d4d4d4", accent: "#94a3b8" },
        { kind: "dark", name: "deepblue", label: "Deep Blue", bg: "#1b1b1f", surface: "#252525", fg: "#d4d4d4", accent: "#3b82f6" },
        { kind: "dark", name: "emerald", label: "Emerald", bg: "#1b1b1f", surface: "#252525", fg: "#d4d4d4", accent: "#10b981" },
        { kind: "dark", name: "goldenamber", label: "Golden Amber", bg: "#1b1b1f", surface: "#252525", fg: "#d4d4d4", accent: "#f59e0b" },
        { kind: "dark", name: "fierysunset", label: "Fiery Sunset", bg: "#1b1b1f", surface: "#252525", fg: "#d4d4d4", accent: "#f97316" },
        { kind: "dark", name: "rosepink", label: "Rose Pink", bg: "#1b1b1f", surface: "#252525", fg: "#d4d4d4", accent: "#ec4899" },
        { kind: "white", name: "mocha", label: "Mocha", bg: "#1e1e2e", surface: "#313244", fg: "#cdd6f4", accent: "#cba6f7" },
        { kind: "white", name: "macchiato", label: "Macchiato", bg: "#24273a", surface: "#363a4f", fg: "#cad3f5", accent: "#c6a0f6" }
    ]

    readonly property bool fromWall: name === "wall"
    property string wallFile: ""
    property string wallStill: ""
    property string wallPick: ""
    property string paintKind: "dark"
    property string paintName: "monochrome"

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
        }
        if (wallFile.length)
            o.wall = wallFile;
        if (wallStill.length)
            o.wallStill = wallStill;
        stateFile.setText(JSON.stringify(o));
    }

    function paint(nextKind, nextName) {
        const n = nextName || name;
        if (n === "wall")
            return;
        paintKind = nextKind || kind;
        paintName = n;
        paintProc.running = false;
        Qt.callLater(() => {
            paintProc.running = true;
        });
    }

    function applyWallJson(d) {
        if (!d || !d.accent)
            return;
        d.kind = "wall";
        d.name = "wall";
        d.label = "From wall";
        applyWallMedia(d);
        apply(d);
        persist("wall", "wall");
    }

    function applyWallMedia(d) {
        if (!d)
            return;
        if (d.wall)
            wallFile = d.wall;
        if (d.wallStill)
            wallStill = d.wallStill;
        else if (d.wall)
            wallStill = d.wall;
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
        id: paintProc
        command: ["python3", `${Quickshell.shellDir}/scripts/tanjun-paint.py`, root.paintKind, root.paintName]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    root.applyWallMedia(JSON.parse(text));
                    root.persist(root.kind, root.name);
                } catch (e) {}
            }
        }
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
        command: ["python3", `${Quickshell.shellDir}/scripts/tanjun-paint.py`, Config.theme.sampleWall ? "set" : "wall", root.wallPick]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    if (d.accent)
                        root.applyWallJson(d);
                    else {
                        root.applyWallMedia(d);
                        root.persist(root.kind, root.name);
                    }
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
                if (s.wall)
                    root.wallFile = s.wall;
                if (s.wallStill)
                    root.wallStill = s.wallStill;
                if (s.name === "wall") {
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
