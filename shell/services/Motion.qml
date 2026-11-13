pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool ready: false

    readonly property var styles: [
        { key: "instant", label: "INSTANT", blurb: "No motion." },
        { key: "quiet", label: "QUIET", blurb: "Pops drop from the bar. Panels rise." },
        { key: "snappy", label: "SNAPPY", blurb: "Short overshoot on every surface." },
        { key: "soft", label: "SOFT", blurb: "Longer travel, slower ease." }
    ]

    readonly property string kind: norm(Config.appearance.motion)
    readonly property var pack: packOf(kind)

    // Speed is a percentage of the preset's own durations. The preset picks the
    // shape of the motion; this scales every duration, so the whole shell can be
    // made quicker or slower without losing that shape. 0 in the config means
    // "not set", which is 100%.
    readonly property int speedMin: 50
    readonly property int speedMax: 200
    readonly property int speedPct: {
        const raw = Math.round(Number(Config.appearance.motionSpeed) || 0);
        if (raw <= 0)
            return 100;
        return Math.max(speedMin, Math.min(speedMax, raw));
    }
    readonly property real speed: speedPct / 100

    function time(ms) {
        const base = Math.max(1, Math.round(ms));
        if (speedPct === 100)
            return base;
        return Math.max(1, Math.round(base * 100 / speedPct));
    }

    readonly property int peek: time(pack.peek)
    readonly property int fast: time(pack.fast)
    readonly property int pop: time(pack.pop)
    readonly property int panel: time(pack.panel)
    readonly property int slow: time(pack.slow)
    readonly property int osdHold: pack.osdHold

    readonly property int easeOut: pack.easeOut
    readonly property int easeIn: pack.easeIn
    readonly property int easeOutBack: pack.easeOutBack
    readonly property int enterEase: pack.enterEase

    readonly property real panelFrom: pack.panelFrom
    readonly property real osdFrom: pack.osdFrom
    readonly property real pressFrom: pack.pressFrom

    readonly property int popY: pack.popY
    readonly property int panelY: pack.panelY
    readonly property int osdY: pack.osdY
    readonly property int toastX: pack.toastX
    readonly property bool spring: pack.spring

    function norm(id) {
        const s = `${id || ""}`.toLowerCase();
        if (s === "off" || s === "none" || s === "instant")
            return "instant";
        if (s === "snappy" || s === "fast")
            return "snappy";
        if (s === "soft" || s === "slow")
            return "soft";
        if (s === "quiet" || s === "default")
            return "quiet";
        return Config.defaultMotion;
    }

    function packOf(k) {
        if (k === "instant")
            return {
                peek: 1, fast: 1, pop: 1, panel: 1, slow: 1, osdHold: 800,
                panelFrom: 1, osdFrom: 1, pressFrom: 1,
                popY: 0, panelY: 0, osdY: 0, toastX: 0,
                spring: false,
                easeOut: Easing.Linear, easeIn: Easing.Linear,
                easeOutBack: Easing.Linear, enterEase: Easing.Linear
            };
        if (k === "snappy")
            return {
                peek: 50, fast: 90, pop: 160, panel: 180, slow: 220, osdHold: 1100,
                panelFrom: 0.97, osdFrom: 0.95, pressFrom: 0.94,
                popY: 6, panelY: 12, osdY: 8, toastX: 20,
                spring: true,
                easeOut: Easing.OutQuad, easeIn: Easing.InQuad,
                easeOutBack: Easing.OutBack, enterEase: Easing.OutBack
            };
        if (k === "soft")
            return {
                peek: 140, fast: 200, pop: 360, panel: 440, slow: 560, osdHold: 1800,
                panelFrom: 0.94, osdFrom: 0.90, pressFrom: 0.97,
                popY: 16, panelY: 24, osdY: 18, toastX: 40,
                spring: true,
                easeOut: Easing.OutCubic, easeIn: Easing.InCubic,
                easeOutBack: Easing.OutBack, enterEase: Easing.OutBack
            };
        return {
            peek: 90, fast: 140, pop: 220, panel: 280, slow: 380, osdHold: 1400,
            panelFrom: 0.97, osdFrom: 0.94, pressFrom: 0.96,
            popY: 10, panelY: 18, osdY: 12, toastX: 32,
            spring: false,
            easeOut: Easing.OutCubic, easeIn: Easing.InCubic,
            easeOutBack: Easing.OutBack, enterEase: Easing.OutCubic
        };
    }

    function styleKeys() {
        const out = [];
        const rows = styles;
        for (let i = 0; i < rows.length; i++)
            out.push(rows[i].key);
        return out;
    }

    function snapshot() {
        return {
            key: kind,
            peek: peek,
            fast: fast,
            pop: pop,
            panel: panel,
            slow: slow,
            osdHold: osdHold,
            panelFrom: panelFrom,
            osdFrom: osdFrom,
            pressFrom: pressFrom,
            popY: popY,
            panelY: panelY,
            osdY: osdY,
            toastX: toastX,
            spring: spring,
            speed: speedPct
        };
    }

    function setSpeed(pct) {
        const n = Number(pct);
        if (!isFinite(n))
            return;
        Config.appearance.motionSpeed = Math.max(speedMin, Math.min(speedMax, Math.round(n)));
        Config.writeSparse();
    }

    function setMotion(id) {
        const k = norm(id);
        Config.appearance.motion = k === Config.defaultMotion ? "" : k;
        Config.writeSparse();
    }

    Component.onCompleted: ready = true
}
