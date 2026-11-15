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
    readonly property string barEdge: {
        const e = `${Config.appearance.barEdge || ""}`.toLowerCase();
        if (e === "top" || e === "bottom" || e === "left" || e === "right")
            return e;
        // An unset pin means the default, so the fallback is read from one place.
        return Config.defaultBarEdge;
    }
    readonly property bool barVertical: barEdge === "left" || barEdge === "right"
    readonly property int barThickness: barVertical ? 40 : barHeight
    readonly property int fontPx: Config.appearance.fontPx > 0 ? Config.appearance.fontPx : Config.defaultFontPx
    readonly property string fontUi: Config.appearance.fontUi.length ? Config.appearance.fontUi : Config.defaultFontUi
    readonly property string fontJp: Config.appearance.fontJp.length ? Config.appearance.fontJp : Config.defaultFontJp
    readonly property string fontIcons: Config.appearance.fontIcons.length ? Config.appearance.fontIcons : Config.defaultFontIcons
    readonly property string fontSeal: sealFont.status === FontLoader.Ready ? sealFont.name : ""
    readonly property string tan: fontSeal.length ? "単" : ""
    readonly property string jun: fontSeal.length ? "純" : ""
    readonly property string defaultStyle: "chrome"
    readonly property var styles: [
        { key: "minimal", label: "Minimal", blurb: "Quiet 1px planes across the shell." },
        { key: "chrome", label: "Chrome", blurb: "Ticks, chips, and marked rails. Palettes unchanged." }
    ]
    readonly property string style: normStyle(Config.appearance.style)
    readonly property bool panelStyle: style === "chrome"
    readonly property bool tick: panelStyle
    readonly property bool tickPops: false
    readonly property bool pip: panelStyle
    readonly property bool railMark: panelStyle
    readonly property bool sliderGlow: panelStyle
    readonly property bool pillToggle: panelStyle
    readonly property int chipBorder: panelStyle ? 1 : 0
    readonly property int tickPlane: 40
    readonly property int tickPop: 18
    readonly property int tickArm: 2
    readonly property int tickPad: 14
    readonly property int thumb: panelStyle ? 12 : 8
    readonly property int barRule: panelStyle ? 1 : 0
    readonly property int brandTracking: panelStyle ? 4 : 0
    readonly property int titleTracking: panelStyle ? 3 : 0
    readonly property int chipTracking: panelStyle ? 1 : 0
    readonly property color caption: panelStyle ? accent : fgSub
    readonly property int captionTracking: panelStyle ? 2 : 0
    readonly property int captionPx: panelStyle ? 11 : 12
    readonly property int cardPad: panelStyle ? 28 : 20
    readonly property color planeBorder: panelStyle ? accent : hairline
    readonly property color popBorder: panelStyle ? accent : hairline
    // A menu hanging off the bar is drawn with the same border as a free card, so
    // it keeps its edges. The edge that meets the bar is not drawn (see
    // Face.attach), so the border traces the menu without cutting it off.
    readonly property color attachBorder: popBorder
    readonly property int attachBorderWidth: panelStyle ? 1 : 0
    readonly property color hot: panelStyle ? wash(accent, 0.10) : surfaceHover
    readonly property color hotSoft: panelStyle ? wash(accent, 0.08) : surfaceHover
    readonly property color barLine: panelStyle ? wash(accent, 0.55) : "transparent"

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

    // Frosted material. The blur is the compositor's: it blurs whatever is
    // actually behind the surface (see compositors/hyprland/modules/rules.lua),
    // so the shell only supplies a translucent tint over it. On a compositor
    // without layer blur the same tint still reads as glass, just unblurred.
    readonly property bool glass: Config.appearance.glass
    // How much of the backdrop the material hides (the elementOpacity token).
    readonly property real glassAlpha: 0.6
    readonly property color glassSurface: Qt.rgba(bg.r, bg.g, bg.b, root.glassAlpha)

    readonly property string wallDir: `${Config.stateDir}/walls`
    readonly property string wallDirLegacy: `${Config.configHome}/hypr/assets/wallpapers`
    readonly property url wallFolder: Qt.url("file://" + wallDir)

    function hexOf(c) {
        const s = `${c}`;
        if (s.startsWith("#") && s.length >= 7)
            return `#${s.slice(-6)}`;
        return s;
    }

    function wash(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
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
            surfaceHover: hexOf(surfaceHover),
            wallDir: root.wallDir,
            wall: wallFile,
            wallStill: wallStill,
            sampleWall: Config.theme.sampleWall
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

    function slug(s, fallback) {
        const t = `${s || ""}`.toLowerCase();
        if (/^[a-z0-9_-]+$/.test(t))
            return t;
        return fallback || "";
    }

    function loadPalette(nextKind, nextName) {
        const n = slug(nextName, "");
        if (!n.length || n === "wall")
            return;
        const k = slug(nextKind, "dark");
        kind = k;
        name = n;
        paletteFile.path = `${Quickshell.shellDir}/themes/${k}/${n}.json`;
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
        if (root.wallFile.length)
            o.wall = root.wallFile;
        if (root.wallStill.length)
            o.wallStill = root.wallStill;
        stateFile.setText(JSON.stringify(o));
    }

    function paint(nextKind, nextName) {
        Wall.paint(nextKind, nextName);
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
        return Wall.urlPath(u);
    }

    function setWallpaper(path) {
        Wall.setWallpaper(path);
    }

    function setSampleWall(on) {
        Config.theme.sampleWall = !!on;
        Config.writeSparse();
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

    function normStyle(id) {
        const s = `${id || ""}`.toLowerCase();
        if (s === "tanjun" || s === "minimal")
            return "minimal";
        if (s === "panel" || s === "chrome")
            return "chrome";
        return defaultStyle;
    }

    function setStyle(id) {
        const next = normStyle(id);
        Config.appearance.style = next === defaultStyle ? "" : next;
        Config.writeSparse();
    }

    function setBarEdge(id) {
        const e = `${id || ""}`.toLowerCase();
        const next = (e === "top" || e === "bottom" || e === "left" || e === "right") ? e : Config.defaultBarEdge;
        // The default edge is stored as an empty pin, so a config that never
        // names an edge keeps following the default.
        Config.appearance.barEdge = next === Config.defaultBarEdge ? "" : next;
        Config.writeSparse();
    }

    function styleKeys() {
        const out = [];
        const rows = styles;
        for (let i = 0; i < rows.length; i++)
            out.push(rows[i].key);
        return out;
    }

    function styleChrome() {
        return {
            key: style,
            tick: tick,
            tickPops: tickPops,
            pip: pip,
            railMark: railMark,
            sliderGlow: sliderGlow,
            pillToggle: pillToggle,
            chipBorder: chipBorder,
            cardPad: cardPad,
            captionTracking: captionTracking,
            barRule: barRule
        };
    }

    function sampleWall() {
        Wall.sample();
    }

    FileView {
        id: stateFile
        path: Config.stateFile
        printErrors: false
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const s = JSON.parse(text());
                root.applyWallMedia(s);
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

    FontLoader {
        id: sealFont
        source: Qt.resolvedUrl("../assets/tanjun-seal.ttf")
    }
}
