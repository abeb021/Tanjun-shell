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
        if (!Compositor.isHypr)
            return;
        gammaProc.running = false;
        Qt.callLater(() => {
            gammaProc.running = true;
        });
    }

    function adopt(out) {
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

    function parseHypr(raw) {
        const out = [];
        for (let i = 0; i < raw.length; i++) {
            const m = raw[i];
            const modes = [];
            const av = m.availableModes || [];
            for (let j = 0; j < av.length; j++)
                modes.push(`${av[j]}`);
            const mode = compactMode(`${Math.round(m.width)}x${Math.round(m.height)}@${m.refreshRate}`);
            out.push({
                name: `${m.name || ""}`,
                desc: `${m.description || m.make || ""}`.trim(),
                width: Math.round(m.width),
                height: Math.round(m.height),
                scale: Number(m.scale) || 1,
                mode: mode,
                modes: modes,
                x: Number(m.x) || 0,
                y: Number(m.y) || 0,
                disabled: !!m.disabled
            });
        }
        adopt(out);
    }

    function parseNiri(raw) {
        const out = [];
        const names = Object.keys(raw);
        for (let i = 0; i < names.length; i++) {
            const key = names[i];
            const m = raw[key] || {};
            const modes = [];
            const av = m.modes || [];
            for (let j = 0; j < av.length; j++) {
                const md = av[j];
                modes.push(`${md.width}x${md.height}@${md.refresh_rate}`);
            }
            const idx = Number(m.current_mode);
            const cur = (idx >= 0 && idx < av.length) ? av[idx] : (av[0] || {});
            const logical = m.logical || {};
            out.push({
                name: `${m.name || key}`,
                desc: `${m.make || ""} ${m.model || ""}`.trim(),
                width: Math.round(cur.width || logical.width || 0),
                height: Math.round(cur.height || logical.height || 0),
                scale: Number(logical.scale) || 1,
                mode: compactMode(`${cur.width}x${cur.height}@${cur.refresh_rate}`),
                modes: modes,
                x: Number(logical.x) || 0,
                y: Number(logical.y) || 0,
                disabled: !m.logical
            });
        }
        adopt(out);
    }

    function parse(text) {
        try {
            const raw = JSON.parse(text);
            if (Array.isArray(raw))
                parseHypr(raw);
            else
                parseNiri(raw);
        } catch (e) {}
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

    function luaSpec(row) {
        const name = `${row.name || ""}`.replace(/"/g, "");
        const mode = compactMode(row.mode);
        const pos = `${Math.round(row.x)}x${Math.round(row.y)}`;
        const sc = Number(row.scale) || 1;
        const off = row.disabled ? "true" : "false";
        return `hl.monitor({ output = "${name}", mode = "${mode}", position = "${pos}", scale = ${sc}, disabled = ${off} })`;
    }

    function patch(row) {
        const rows = list.slice();
        for (let i = 0; i < rows.length; i++) {
            if (rows[i].name === row.name)
                rows[i] = row;
        }
        list = rows;
    }

    function applyNiri(row) {
        const name = `${row.name || ""}`;
        if (!name.length)
            return;
        const sc = Number(row.scale) || 1;
        const mode = compactMode(row.mode);
        Quickshell.execDetached(["niri", "msg", "output", name, "scale", `${sc}`]);
        if (mode.length)
            Quickshell.execDetached(["niri", "msg", "output", name, "mode", mode]);
        Qt.callLater(root.refresh);
    }

    function apply(row) {
        if (!row || !row.name)
            return;
        patch(row);
        persist();
        if (Compositor.isNiri) {
            applyNiri(row);
            return;
        }
        applyProc.command = ["hyprctl", "eval", luaSpec(row)];
        applyProc.running = false;
        Qt.callLater(() => {
            applyProc.running = true;
        });
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
        if (!Compositor.isHypr)
            return;
        const n = Math.max(50, Math.min(150, Math.round(v)));
        gamma = n;
        gammaLive = true;
        Quickshell.execDetached(["hyprctl", "hyprsunset", "gamma", `${n}`]);
        gammaWrite.restart();
    }

    function identity() {
        if (!Compositor.isHypr)
            return;
        gammaLive = false;
        Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"]);
        Config.screens.gamma = 0;
        Config.writeSparse();
    }

    function persistNiri() {
        const rows = list;
        let body = "// Outputs. Written by Settings → screen.\n\n";
        for (let i = 0; i < rows.length; i++) {
            const r = rows[i];
            if (r.disabled)
                continue;
            body += `output "${r.name}" {\n`;
            body += `    mode "${compactMode(r.mode)}"\n`;
            body += `    scale ${Number(r.scale) || 1}\n`;
            body += `    position x=${Math.round(r.x)} y=${Math.round(r.y)}\n`;
            body += "}\n\n";
        }
        Config.ensureStateDir();
        pinFile.path = `${Config.configHome}/niri/output.kdl`;
        pinFile.setText(body);
    }

    function persist() {
        if (Compositor.isNiri) {
            persistNiri();
            return;
        }
        const rows = list;
        let body = "---@module 'hl'\n\n";
        for (let i = 0; i < rows.length; i++) {
            const r = rows[i];
            if (r.disabled)
                continue;
            body += "hl.monitor({\n";
            body += `    output = "${r.name}",\n`;
            body += `    mode = "${compactMode(r.mode)}",\n`;
            body += `    position = "${Math.round(r.x)}x${Math.round(r.y)}",\n`;
            body += `    scale = ${Number(r.scale) || 1},\n`;
            body += "})\n\n";
        }
        Config.ensureStateDir();
        pinFile.path = `${Config.configHome}/hypr/monitors.lua`;
        pinFile.setText(body);
    }

    Process {
        id: applyProc
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: Qt.callLater(root.refresh)
        }
    }

    Process {
        id: monProc
        command: Compositor.isNiri ? ["niri", "msg", "--json", "outputs"] : ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parse(text)
        }
    }

    Process {
        id: gammaProc
        command: ["hyprctl", "hyprsunset", "gamma"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (!Compositor.isHypr)
                    return;
                const n = parseInt(text.trim(), 10);
                if (!isNaN(n) && n > 0)
                    root.gamma = n;
            }
        }
    }

    FileView {
        id: pinFile
        printErrors: false
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
