pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var list: []
    property string pick: ""
    property real scale: 1
    property bool hold: false
    property int gamma: 100
    property bool gammaLive: false

    readonly property var current: {
        const rows = list;
        for (let i = 0; i < rows.length; i++) {
            if (rows[i].name === pick)
                return rows[i];
        }
        return rows.length ? rows[0] : null;
    }

    readonly property var scales: [1, 1.2, 1.25, 1.5, 1.75, 2]

    function snapScale(raw) {
        const stops = scales;
        if (!stops.length)
            return 1;
        let n = Number(raw);
        if (!(n > 0))
            n = 1;
        let best = stops[0];
        let bestD = Math.abs(n - best);
        for (let i = 1; i < stops.length; i++) {
            const d = Math.abs(n - stops[i]);
            if (d < bestD) {
                best = stops[i];
                bestD = d;
            }
        }
        return best;
    }

    function scaleIndex(raw) {
        const stops = scales;
        const n = snapScale(raw);
        for (let i = 0; i < stops.length; i++) {
            if (Math.abs(stops[i] - n) < 0.001)
                return i;
        }
        return 0;
    }

    function scaleAt(t) {
        const stops = scales;
        if (!stops.length)
            return 1;
        const last = stops.length - 1;
        const i = Math.max(0, Math.min(last, Math.round(Math.max(0, Math.min(1, Number(t) || 0)) * last)));
        return stops[i];
    }

    function scaleSlider(raw) {
        const last = scales.length - 1;
        if (last <= 0)
            return 0;
        return scaleIndex(raw) / last;
    }

    function fmtScale(raw) {
        const n = snapScale(raw);
        return `${n}`.replace(/(\.\d*?)0+$/, "$1").replace(/\.$/, "");
    }

    function compactMode(s) {
        let t = `${s || ""}`.replace(/\s/g, "").replace(/Hz$/i, "");
        t = t.replace(/@(\d+(?:\.\d+)?)$/, (_, n) => {
            const hz = Number(n);
            if (!hz)
                return `@${n}`;
            if (Math.abs(hz - Math.round(hz)) < 0.05)
                return `@${Math.round(hz)}`;
            const t3 = Math.round(hz * 1000) / 1000;
            return `@${t3}`;
        });
        return t;
    }

    function sameMode(a, b) {
        return compactMode(a) === compactMode(b);
    }

    function refresh() {
        monProc.running = false;
        Qt.callLater(() => {
            monProc.running = true;
        });
        if (!Compositor.hasGamma)
            return;
        gammaProc.running = false;
        Qt.callLater(() => {
            gammaProc.running = true;
        });
    }

    function adopt(out) {
        for (let i = 0; i < out.length; i++) {
            out[i].mode = compactMode(out[i].mode);
            const modes = out[i].modes || [];
            for (let j = 0; j < modes.length; j++)
                modes[j] = compactMode(modes[j]);
            out[i].modes = modes;
        }
        list = out;
        if (!pick.length && out.length)
            pick = out[0].name;
        else {
            let hit = false;
            for (let i = 0; i < out.length; i++) {
                if (out[i].name === pick)
                    hit = true;
            }
            if (!hit && out.length)
                pick = out[0].name;
        }
        syncScale();
    }

    function parse(text) {
        const rows = Compositor.parseMonitors(text);
        if (rows)
            adopt(rows);
    }

    function syncScale() {
        const cur = current;
        if (!cur)
            return;
        const sc = Number(cur.scale) || 1;
        if (hold) {
            if (Math.abs(sc - scale) < 0.02)
                hold = false;
            return;
        }
        scale = sc;
    }

    onPickChanged: {
        hold = false;
        syncScale();
    }

    function patch(row) {
        const rows = list.slice();
        for (let i = 0; i < rows.length; i++) {
            if (rows[i].name === row.name)
                rows[i] = row;
        }
        list = rows;
    }

    function apply(row) {
        if (!row || !row.name)
            return;
        patch(row);
        Compositor.persistMonitors(list);
        Compositor.applyMonitor(row);
    }

    function setScale(v) {
        const cur = current;
        if (!cur)
            return;
        scale = snapScale(v);
        hold = true;
        const next = Object.assign({}, cur);
        next.scale = scale;
        apply(next);
    }

    function setMode(mode) {
        const cur = current;
        if (!cur)
            return;
        const next = Object.assign({}, cur);
        next.mode = compactMode(mode);
        apply(next);
    }

    function setGamma(v) {
        if (!Compositor.hasGamma)
            return;
        const n = Math.max(50, Math.min(150, Math.round(v)));
        gamma = n;
        gammaLive = true;
        Compositor.setGamma(n);
        gammaWrite.restart();
    }

    function identity() {
        if (!Compositor.hasGamma)
            return;
        gammaLive = false;
        Compositor.identityGamma();
        Config.screens.gamma = 0;
        Config.writeSparse();
    }

    Process {
        id: monProc
        command: Compositor.monitorQuery
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parse(text)
        }
    }

    Process {
        id: gammaProc
        command: Compositor.gammaQuery
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (!Compositor.hasGamma)
                    return;
                const n = Compositor.readGamma(text);
                if (n)
                    root.gamma = n;
            }
        }
    }

    Connections {
        target: Compositor
        function onMonitorsDirty() {
            root.refresh();
        }
    }

    Timer {
        id: gammaWrite
        interval: 400
        onTriggered: {
            Config.screens.gamma = root.gamma;
            Config.writeSparse();
        }
    }

    Component.onCompleted: refresh()

    function cloneRow(r) {
        return {
            name: r.name,
            desc: r.desc,
            width: r.width,
            height: r.height,
            scale: r.scale,
            mode: r.mode,
            modes: r.modes,
            x: r.x,
            y: r.y,
            disabled: r.disabled
        };
    }

    function internalOf(rows) {
        for (let i = 0; i < rows.length; i++) {
            const n = `${rows[i].name || ""}`;
            if (n.indexOf("eDP") === 0 || n.indexOf("LVDS") === 0)
                return rows[i];
        }
        return rows.length ? rows[0] : null;
    }

    function setDesk(kind) {
        const src = list || [];
        if (!src.length)
            return;
        const rows = [];
        for (let i = 0; i < src.length; i++)
            rows.push(cloneRow(src[i]));
        const internal = internalOf(rows);
        if (!internal)
            return;
        let external = null;
        for (let i = 0; i < rows.length; i++) {
            if (rows[i].name !== internal.name) {
                external = rows[i];
                break;
            }
        }
        if (kind === "first") {
            for (let i = 0; i < rows.length; i++) {
                rows[i].disabled = rows[i].name !== internal.name;
                if (!rows[i].disabled) {
                    rows[i].x = 0;
                    rows[i].y = 0;
                }
            }
        } else if (kind === "second" && external) {
            for (let i = 0; i < rows.length; i++) {
                rows[i].disabled = rows[i].name !== external.name;
                if (!rows[i].disabled) {
                    rows[i].x = 0;
                    rows[i].y = 0;
                }
            }
        } else if (kind === "extend" && external) {
            for (let i = 0; i < rows.length; i++)
                rows[i].disabled = false;
            external.x = 0;
            external.y = 0;
            internal.x = Number(external.width) || 1920;
            internal.y = 0;
        } else {
            return;
        }
        list = rows;
        Compositor.persistMonitors(rows);
        for (let i = 0; i < rows.length; i++)
            Compositor.applyMonitor(rows[i]);
    }
}
