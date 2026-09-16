import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root
    property bool live: false

    readonly property bool hasGamma: true
    readonly property bool grabFocus: true
    readonly property string screenNote: "scale and mode persist in ~/.config/hypr/monitors.lua."
    readonly property var monitorQuery: ["hyprctl", "monitors", "-j"]
    readonly property var gammaQuery: ["hyprctl", "hyprsunset", "gamma"]

    signal applied
    signal overviewWanted

    readonly property string focusedOutput: {
        const m = Hyprland.focusedMonitor;
        return m && m.name ? `${m.name}` : "";
    }

    readonly property int focusedWorkspaceId: {
        const ws = Hyprland.focusedWorkspace;
        return ws && ws.id ? ws.id : 0;
    }

    readonly property var occupied: {
        const out = {};
        const list = Hyprland.workspaces.values;
        if (list) {
            for (let i = 0; i < list.length; i++) {
                const id = list[i].id;
                if (id > 0 && id <= 10)
                    out[id] = true;
            }
        }
        return out;
    }

    property string layoutName: ""

    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`
    readonly property string hyprKbName: "hyprctl devices -j | python -c \"import json,sys; d=json.load(sys.stdin); ks=d.get('keyboards',[]); k=next((x for x in ks if x.get('main')), ks[0] if ks else {}); print(k.get('name',''))\""

    function hyprDispatch(legacy, lua) {
        Hyprland.dispatch(Hyprland.usingLua ? lua : legacy);
    }

    function activateWorkspace(id) {
        const n = Number(id);
        if (!n)
            return;
        hyprDispatch(`workspace ${n}`, `hl.dsp.focus({ workspace = ${n} })`);
    }

    function moveToWorkspace(id) {
        const n = Number(id);
        if (!n)
            return;
        hyprDispatch(`movetoworkspace ${n}`, `hl.dsp.window.move({ workspace = ${n} })`);
    }

    function cycleWorkspace(delta) {
        const sel = delta > 0 ? "e-1" : "e+1";
        hyprDispatch(`workspace ${sel}`, `hl.dsp.focus({ workspace = "${sel}" })`);
    }

    function exitSession() {
        hyprDispatch("exit", "hl.dsp.exit()");
    }

    function toggleOverview() {
        overviewWanted();
    }

    function focusWindow(addr) {
        const a = `${addr || ""}`;
        if (!a.length)
            return;
        hyprDispatch(`focuswindow address:${a}`, `hl.dsp.focus({ window = "address:${a}" })`);
    }

    function cycleLayout(keyboard) {
        const quoted = keyboard && `${keyboard}`.length ? `'${String(keyboard).replace(/'/g, "'\\''")}'` : `"$(${root.hyprKbName})"`;
        Quickshell.execDetached(["bash", "-c", `hyprctl switchxkblayout ${quoted} next`]);
    }

    function parseMonitors(text) {
        try {
            const raw = JSON.parse(text);
            if (!Array.isArray(raw))
                return null;
            const out = [];
            for (let i = 0; i < raw.length; i++) {
                const m = raw[i];
                const modes = [];
                const av = m.availableModes || [];
                for (let j = 0; j < av.length; j++)
                    modes.push(`${av[j]}`);
                out.push({
                    name: `${m.name || ""}`,
                    desc: `${m.description || m.make || ""}`.trim(),
                    width: Math.round(m.width),
                    height: Math.round(m.height),
                    scale: Number(m.scale) || 1,
                    mode: `${Math.round(m.width)}x${Math.round(m.height)}@${m.refreshRate}`,
                    modes: modes,
                    x: Number(m.x) || 0,
                    y: Number(m.y) || 0,
                    disabled: !!m.disabled
                });
            }
            return out;
        } catch (e) {
            return null;
        }
    }

    function applyMonitor(row) {
        const name = `${row.name || ""}`.replace(/"/g, "");
        const mode = `${row.mode || ""}`;
        const pos = `${Math.round(row.x)}x${Math.round(row.y)}`;
        const sc = Number(row.scale) || 1;
        const off = row.disabled ? "true" : "false";
        applyProc.command = ["hyprctl", "eval", `hl.monitor({ output = "${name}", mode = "${mode}", position = "${pos}", scale = ${sc}, disabled = ${off} })`];
        applyProc.running = false;
        Qt.callLater(() => {
            applyProc.running = true;
        });
    }

    function persistMonitors(rows) {
        let body = "---@module 'hl'\n\n";
        for (let i = 0; i < rows.length; i++) {
            const r = rows[i];
            if (r.disabled)
                continue;
            body += "hl.monitor({\n";
            body += `    output = "${r.name}",\n`;
            body += `    mode = "${r.mode}",\n`;
            body += `    position = "${Math.round(r.x)}x${Math.round(r.y)}",\n`;
            body += `    scale = ${Number(r.scale) || 1},\n`;
            body += "})\n\n";
        }
        const dir = `${configHome}/hypr`;
        Quickshell.execDetached(["mkdir", "-p", dir]);
        pinFile.path = `${dir}/monitors.lua`;
        pinFile.setText(body);
    }

    function setGamma(n) {
        Quickshell.execDetached(["hyprctl", "hyprsunset", "gamma", `${n}`]);
    }

    function identityGamma() {
        Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"]);
    }

    function readGamma(text) {
        const n = parseInt(`${text || ""}`.trim(), 10);
        return (!isNaN(n) && n > 0) ? n : 0;
    }

    function refreshLayout() {
        if (!live)
            return;
        layoutProc.running = false;
        Qt.callLater(() => {
            layoutProc.running = true;
        });
    }

    Process {
        id: applyProc
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.applied()
        }
    }

    Process {
        id: layoutProc
        command: ["bash", "-c", "hyprctl devices -j | python -c \"import json,sys; d=json.load(sys.stdin); ks=d.get('keyboards',[]); k=next((x for x in ks if x.get('main')), ks[0] if ks else {}); print(k.get('name',''))\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.layoutName = text.trim()
        }
    }

    Connections {
        target: Hyprland
        enabled: root.live
        function onRawEvent(event) {
            if (event.name === "activelayout")
                root.refreshLayout();
        }
    }

    FileView {
        id: pinFile
        printErrors: false
    }

    Component.onCompleted: refreshLayout()
}
