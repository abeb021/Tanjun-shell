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
        scale = Number(v) || 1;
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
}
