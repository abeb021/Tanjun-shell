import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

HostBase {
    id: root

    hasGamma: false
    grabFocus: false
    screenNote: "scale and mode persist in ~/.config/niri/output.kdl."
    monitorQuery: ["niri", "msg", "--json", "outputs"]
    gammaQuery: ["true"]

    property var niriOccupied: ({})
    property var niriActiveIds: []
    property var niriIdToIdx: ({})
    property var windowList: []
    property int niriFocusedId: 0
    property string niriFocusedOutput: ""

    focusedOutput: niriFocusedOutput
    focusedWorkspaceId: niriFocusedId
    occupied: niriOccupied
    activeIds: niriActiveIds
    windows: overviewOpen ? windowList : []
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
        overviewWanted();
    }

    function pullWindows() {
        if (!live || !overviewOpen)
            return;
        windowsProc.running = false;
        windowsProc.running = true;
    }

    function refreshWindows() {
        if (!live || !overviewOpen)
            return;
        winDebounce.restart();
    }

    function setDpms(on) {
        Quickshell.execDetached(["niri", "msg", "action", on ? "power-on-monitors" : "power-off-monitors"]);
    }

    function captureOf(appId, title) {
        const list = ToplevelManager.toplevels.values;
        if (!list)
            return null;
        const app = `${appId || ""}`;
        const ttl = `${title || ""}`;
        let byApp = null;
        for (let i = 0; i < list.length; i++) {
            const t = list[i];
            if (`${t.appId}` !== app)
                continue;
            if (`${t.title}` === ttl)
                return t;
            if (!byApp)
                byApp = t;
        }
        return byApp;
    }

    function ingestWindows(raw) {
        const list = Array.isArray(raw) ? raw : (raw && raw.windows) || [];
        ingestWindowOcc(list);
        if (!overviewOpen) {
            if (windowList.length)
                windowList = [];
            return;
        }
        const map = niriIdToIdx || {};
        const prev = windowList;
        const byAddr = {};
        for (let i = 0; i < prev.length; i++)
            byAddr[`${prev[i].addr}`] = prev[i];
        const out = [];
        for (let i = 0; i < list.length; i++) {
            const w = list[i];
            const idx = Number(map[w.workspace_id]) || 0;
            const addr = `${w.id || ""}`;
            const title = `${w.title || ""}`;
            const appId = `${w.app_id || ""}`;
            const output = `${w.output || ""}`;
            const activated = !!w.is_focused;
            const row = byAddr[addr];
            const capture = (row && row.capture) ? row.capture : captureOf(w.app_id, w.title);
            out.push({
                title: title,
                appId: appId,
                addr: addr,
                workspaceId: idx,
                output: output,
                capture: capture,
                activated: activated
            });
        }
        let same = out.length === prev.length;
        if (same) {
            for (let i = 0; i < out.length; i++) {
                const a = out[i];
                const b = prev[i];
                if (a.addr !== b.addr || a.title !== b.title || a.appId !== b.appId || a.workspaceId !== b.workspaceId || a.output !== b.output || a.activated !== b.activated) {
                    same = false;
                    break;
                }
            }
        }
        if (!same)
            windowList = out;
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

    function sameOcc(a, b) {
        if (!a || !b)
            return false;
        for (let i = 1; i <= 10; i++) {
            if (!!a[i] !== !!b[i])
                return false;
        }
        return true;
    }

    function sameIds(a, b) {
        if (!a || !b || a.length !== b.length)
            return false;
        for (let i = 0; i < a.length; i++) {
            if (Number(a[i]) !== Number(b[i]))
                return false;
        }
        return true;
    }

    function ingestWindowOcc(list) {
        const map = niriIdToIdx || {};
        const occ = {};
        if (list) {
            for (let i = 0; i < list.length; i++) {
                const w = list[i];
                if (!w)
                    continue;
                const idx = Number(map[w.workspace_id]) || 0;
                if (idx > 0 && idx <= 10)
                    occ[idx] = true;
            }
        }
        niriOccupied = sameOcc(niriOccupied, occ) ? niriOccupied : occ;
    }

    function ingestWorkspaces(list) {
        if (!list || !list.length)
            return;
        const occ = {};
        const idMap = {};
        const active = [];
        const byOut = {};
        const seen = {};
        let focusId = 0;
        let focusOut = "";
        for (let i = 0; i < list.length; i++) {
            const ws = list[i];
            const idx = Number(ws.idx) || 0;
            if (ws.id !== undefined)
                idMap[ws.id] = idx;
            const wid = ws.active_window_id;
            if (idx > 0 && idx <= 10 && wid !== undefined && wid !== null && `${wid}` !== "" && Number(wid) !== 0)
                occ[idx] = true;
            if (idx > 0 && idx <= 10 && (ws.is_active || ws.is_focused) && !seen[idx]) {
                seen[idx] = true;
                active.push(idx);
            }
            if (idx > 0 && idx <= 10 && (ws.is_active || ws.is_focused)) {
                const name = `${ws.output || ""}`;
                if (name.length)
                    byOut[name] = idx;
            }
            if (ws.is_focused) {
                focusId = idx;
                focusOut = `${ws.output || ""}`;
            }
        }
        active.sort((a, b) => a - b);
        niriIdToIdx = idMap;
        niriOccupied = sameOcc(niriOccupied, occ) ? niriOccupied : occ;
        if (!sameIds(niriActiveIds, active))
            niriActiveIds = active;
        activeByOutput = byOut;
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
            if (ev.WindowsChanged && ev.WindowsChanged.windows)
                ingestWindowOcc(ev.WindowsChanged.windows);
            if (ev.WindowsChanged || ev.WindowOpenedOrChanged || ev.WindowClosed)
                root.refreshWindows();
            if (ev.WindowOpenedOrChanged || ev.WindowClosed || (ev.WorkspaceActivated && ev.WorkspaceActivated.focused)) {
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

    function testHost() {
        return `${Quickshell.env("TANJUN_TEST") || ""}` === "1";
    }

    function applyMonitor(row) {
        applyMonitors(row ? [row] : []);
    }

    function applyMonitors(rows) {
        if (!rows || !rows.length || testHost())
            return;
        for (let i = 0; i < rows.length; i++) {
            const row = rows[i];
            const name = `${row.name || ""}`;
            if (!name.length)
                continue;
            if (row.disabled) {
                Quickshell.execDetached(["niri", "msg", "output", name, "off"]);
                continue;
            }
            Quickshell.execDetached(["niri", "msg", "output", name, "on"]);
            const sc = Number(row.scale) || 1;
            const mode = `${row.mode || ""}`;
            Quickshell.execDetached(["niri", "msg", "output", name, "scale", `${sc}`]);
            if (mode.length)
                Quickshell.execDetached(["niri", "msg", "output", name, "mode", mode]);
            Quickshell.execDetached(["niri", "msg", "output", name, "position", "set", `${Math.round(row.x)}`, `${Math.round(row.y)}`]);
        }
        Qt.callLater(() => root.applied());
    }

    function kdlStr(s) {
        return String(s || "").replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/[\r\n]/g, " ");
    }

    property string _pinBody: ""

    function persistMonitors(rows) {
        let body = "// Outputs. Written by Settings → screen.\n\n";
        for (let i = 0; i < rows.length; i++) {
            const r = rows[i];
            body += `output "${kdlStr(r.name)}" {\n`;
            if (r.disabled) {
                body += "    off\n";
                body += "}\n\n";
                continue;
            }
            body += `    mode "${kdlStr(r.mode)}"\n`;
            body += `    scale ${Number(r.scale) || 1}\n`;
            body += `    position x=${Math.round(r.x)} y=${Math.round(r.y)}\n`;
            body += "}\n\n";
        }
        _pinBody = body;
        pinMk.command = ["mkdir", "-p", `${configHome}/niri`];
        pinMk.running = false;
        Qt.callLater(() => {
            pinMk.running = true;
        });
    }

    function setGamma(n) {}
    function identityGamma() {}
    function setTemperature(n) {}
    function reloadSunset() {}
    function ensureSunset() {}
    function readGamma(text) {
        return 0;
    }

    Timer {
        id: winDebounce
        interval: 50
        repeat: false
        onTriggered: root.pullWindows()
    }

    Process {
        id: windowsProc
        command: ["niri", "msg", "--json", "windows"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    root.ingestWindows(JSON.parse(text));
                } catch (e) {}
            }
        }
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

    Process {
        id: pinMk
        running: false
        onExited: {
            pinFile.path = `${root.configHome}/niri/output.kdl`;
            pinFile.setText(root._pinBody);
        }
    }

    FileView {
        id: pinFile
        printErrors: false
        atomicWrites: true
    }

    onOverviewOpenChanged: {
        if (overviewOpen)
            pullWindows();
        else
            windowList = [];
    }

    Component.onCompleted: {
        if (!live)
            return;
        refreshProc.running = true;
        layoutsProc.running = true;
    }
}
