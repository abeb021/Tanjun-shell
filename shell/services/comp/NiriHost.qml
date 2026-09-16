import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool live: false

    readonly property bool hasGamma: false
    readonly property bool grabFocus: false
    readonly property string screenNote: "scale and mode persist in ~/.config/niri/output.kdl."
    readonly property var monitorQuery: ["niri", "msg", "--json", "outputs"]
    readonly property var gammaQuery: ["true"]

    signal applied

    property var niriOccupied: ({})
    property int niriFocusedId: 0
    property string niriFocusedOutput: ""
    property string layoutName: ""

    readonly property string focusedOutput: niriFocusedOutput
    readonly property int focusedWorkspaceId: niriFocusedId
    readonly property var occupied: niriOccupied
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`

    function activateWorkspace(id) {
        const n = Number(id);
        if (!n)
            return;
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", "--", `${n}`]);
    }

    function moveToWorkspace(id) {
        const n = Number(id);
        if (!n)
            return;
        Quickshell.execDetached(["niri", "msg", "action", "move-window-to-workspace", "--", `${n}`]);
    }

    function cycleWorkspace(delta) {
        Quickshell.execDetached(["niri", "msg", "action", delta > 0 ? "focus-workspace-up" : "focus-workspace-down"]);
    }

    function exitSession() {
        Quickshell.execDetached(["niri", "msg", "action", "quit"]);
    }

    function toggleOverview() {
        Quickshell.execDetached(["niri", "msg", "action", "toggle-overview"]);
    }

    function focusWindow(addr) {
        const a = `${addr || ""}`;
        if (!a.length)
            return;
        Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--", a]);
    }

    function cycleLayout(keyboard) {
        Quickshell.execDetached(["niri", "msg", "action", "switch-layout", "next"]);
    }

    function ingestWorkspaces(list) {
        if (!list || !list.length)
            return;
        const occ = {};
        let focusId = 0;
        let focusOut = "";
        for (let i = 0; i < list.length; i++) {
            const ws = list[i];
            const idx = Number(ws.idx) || 0;
            if (idx > 0 && idx <= 10)
                occ[idx] = true;
            if (ws.is_focused) {
                focusId = idx;
                focusOut = `${ws.output || ""}`;
            }
        }
        niriOccupied = occ;
        if (focusId)
            niriFocusedId = focusId;
        if (focusOut.length)
            niriFocusedOutput = focusOut;
    }

    function ingestLayouts(obj) {
        if (!obj)
            return;
        const names = obj.names || [];
        const idx = Number(obj.current_idx);
        layoutName = (idx >= 0 && idx < names.length) ? `${names[idx]}` : "";
    }

    function onEvent(line) {
        const s = `${line || ""}`.trim();
        if (!s.length)
            return;
        try {
            const ev = JSON.parse(s);
            if (ev.WorkspacesChanged && ev.WorkspacesChanged.workspaces)
                ingestWorkspaces(ev.WorkspacesChanged.workspaces);
            if (ev.WorkspaceActivated && ev.WorkspaceActivated.focused) {
                refreshProc.running = false;
                Qt.callLater(() => {
                    refreshProc.running = true;
                });
            }
            if (ev.KeyboardLayoutsChanged && ev.KeyboardLayoutsChanged.keyboard_layouts)
                ingestLayouts(ev.KeyboardLayoutsChanged.keyboard_layouts);
            if (ev.KeyboardLayoutSwitched) {
                layoutsProc.running = false;
                Qt.callLater(() => {
                    layoutsProc.running = true;
                });
            }
        } catch (e) {}
    }

    function parseMonitors(text) {
        try {
            const raw = JSON.parse(text);
            if (!raw || Array.isArray(raw))
                return null;
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
                    mode: `${cur.width}x${cur.height}@${cur.refresh_rate}`,
                    modes: modes,
                    x: Number(logical.x) || 0,
                    y: Number(logical.y) || 0,
                    disabled: !m.logical
                });
            }
            return out;
        } catch (e) {
            return null;
        }
    }

    function applyMonitor(row) {
        const name = `${row.name || ""}`;
        if (!name.length)
            return;
        const sc = Number(row.scale) || 1;
        const mode = `${row.mode || ""}`;
        Quickshell.execDetached(["niri", "msg", "output", name, "scale", `${sc}`]);
        if (mode.length)
            Quickshell.execDetached(["niri", "msg", "output", name, "mode", mode]);
        Qt.callLater(() => root.applied());
    }

    function persistMonitors(rows) {
        let body = "// Outputs. Written by Settings → screen.\n\n";
        for (let i = 0; i < rows.length; i++) {
            const r = rows[i];
            if (r.disabled)
                continue;
            body += `output "${r.name}" {\n`;
            body += `    mode "${r.mode}"\n`;
            body += `    scale ${Number(r.scale) || 1}\n`;
            body += `    position x=${Math.round(r.x)} y=${Math.round(r.y)}\n`;
            body += "}\n\n";
        }
        const dir = `${configHome}/niri`;
        Quickshell.execDetached(["mkdir", "-p", dir]);
        pinFile.path = `${dir}/output.kdl`;
        pinFile.setText(body);
    }

    function setGamma(n) {}
    function identityGamma() {}
    function readGamma(text) {
        return 0;
    }

    Process {
        id: refreshProc
        command: ["niri", "msg", "--json", "workspaces"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    root.ingestWorkspaces(JSON.parse(text));
                } catch (e) {}
            }
        }
    }

    Process {
        id: layoutsProc
        command: ["niri", "msg", "--json", "keyboard-layouts"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    root.ingestLayouts(JSON.parse(text));
                } catch (e) {}
            }
        }
    }

    Process {
        id: eventsProc
        command: ["niri", "msg", "--json", "event-stream"]
        running: root.live
        stdout: SplitParser {
            onRead: line => root.onEvent(line)
        }
    }

    FileView {
        id: pinFile
        printErrors: false
    }

    Component.onCompleted: {
        if (!live)
            return;
        refreshProc.running = true;
        layoutsProc.running = true;
    }
}
