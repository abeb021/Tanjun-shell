import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

HostBase {
    id: root

    hasGamma: true
    grabFocus: true
    screenNote: "scale and mode persist in ~/.config/hypr/monitors.lua."
    monitorQuery: ["hyprctl", "monitors", "-j"]
    gammaQuery: ["hyprctl", "hyprsunset", "gamma"]

    property var windowList: []
    property string kbName: ""
    windows: overviewOpen ? windowList : []

    focusedOutput: {
        const m = Hyprland.focusedMonitor;
        return m && m.name ? `${m.name}` : "";
    }

    focusedWorkspaceId: {
        const ws = Hyprland.focusedWorkspace;
        return ws && ws.id ? ws.id : 0;
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

    function ingestClients(text) {
        try {
            const raw = JSON.parse(text);
            if (!Array.isArray(raw))
                return;
            const out = {};
            for (let i = 0; i < raw.length; i++) {
                const c = raw[i];
                if (!c || c.hidden || c.mapped === false)
                    continue;
                const ws = c.workspace || {};
                const id = Number(ws.id) || 0;
                if (id > 0 && id <= 10)
                    out[id] = true;
            }
            if (!sameOcc(occupied, out))
                occupied = out;
        } catch (e) {}
    }

    function ingestMonitors(text) {
        try {
            const raw = JSON.parse(text);
            if (!Array.isArray(raw))
                return;
            const ids = [];
            const byOut = {};
            const seen = {};
            for (let i = 0; i < raw.length; i++) {
                const m = raw[i];
                if (!m)
                    continue;
                const aw = m.activeWorkspace || {};
                const id = Number(aw.id) || 0;
                const name = `${m.name || ""}`;
                if (id > 0 && id <= 10) {
                    if (!seen[id]) {
                        seen[id] = true;
                        ids.push(id);
                    }
                    if (name.length)
                        byOut[name] = id;
                }
            }
            ids.sort((a, b) => a - b);
            if (!sameIds(activeIds, ids))
                activeIds = ids;
            activeByOutput = byOut;
        } catch (e) {}
    }

    function syncOccupied() {
        if (!live)
            return;
        occDelay.restart();
    }

    function scanIdle() {
        if (!live) {
            if (idleInhibited)
                idleInhibited = false;
            return;
        }
        const list = Hyprland.toplevels.values;
        let found = false;
        if (list) {
            for (let i = 0; i < list.length; i++) {
                const tl = list[i];
                if (!tl)
                    continue;
                const ipc = tl.lastIpcObject || {};
                const inh = `${ipc.idleInhibit || ipc.idle_inhibit || ""}`.toLowerCase();
                const full = !!(ipc.fullscreen || tl.fullscreen);
                const focused = !!tl.activated;
                if (inh === "always" || (inh === "fullscreen" && full) || (inh === "focus" && focused)) {
                    found = true;
                    break;
                }
            }
        }
        if (idleInhibited !== found)
            idleInhibited = found;
    }

    function syncWindows() {
        if (!live || !overviewOpen) {
            if (windowList.length)
                windowList = [];
            return;
        }
        const list = Hyprland.toplevels.values;
        const prev = windowList;
        const byAddr = {};
        for (let i = 0; i < prev.length; i++)
            byAddr[prev[i].addr] = prev[i];
        const out = [];
        if (list) {
            for (let i = 0; i < list.length; i++) {
                const tl = list[i];
                if (!tl)
                    continue;
                const ipc = tl.lastIpcObject || {};
                if (ipc.hidden || ipc.mapped === false)
                    continue;
                const ws = tl.workspace;
                const id = ws && ws.id ? ws.id : 0;
                if (id < 1 || id > 10)
                    continue;
                const mon = tl.monitor;
                const addr = `${tl.address || ipc.address || ""}`;
                const key = addr.indexOf("0x") === 0 || !addr.length ? addr : `0x${addr}`;
                const title = `${tl.title || ipc.title || ""}`;
                const appId = `${ipc.class || ""}`;
                const output = mon && mon.name ? `${mon.name}` : "";
                const capture = tl.wayland || null;
                const activated = !!tl.activated;
                const row = byAddr[key];
                out.push({
                    title: title,
                    appId: appId,
                    addr: key,
                    workspaceId: id,
                    output: output,
                    capture: (row && row.capture) ? row.capture : capture,
                    activated: activated
                });
            }
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

    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`

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

    function refreshWindows() {
        if (live)
            Hyprland.refreshToplevels();
        syncWindows();
    }

    function setDpms(on) {
        Quickshell.execDetached(["hyprctl", "dispatch", "dpms", on ? "on" : "off"]);
    }

    function focusWindow(addr) {
        const a = `${addr || ""}`;
        if (!a.length)
            return;
        hyprDispatch(`focuswindow address:${a}`, `hl.dsp.focus({ window = "address:${a}" })`);
    }

    function cycleLayout(keyboard) {
        const name = (keyboard && `${keyboard}`.length) ? `${keyboard}` : root.kbName;
        if (!name.length) {
            refreshLayout();
            return;
        }
        Quickshell.execDetached(["hyprctl", "switchxkblayout", name, "next"]);
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

    function luaStr(s) {
        return String(s || "").replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/[\r\n]/g, " ");
    }

    function applyMonitor(row) {
        const name = luaStr(`${row.name || ""}`.replace(/"/g, ""));
        const mode = luaStr(`${row.mode || ""}`);
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
            body += "hl.monitor({\n";
            body += `    output = "${luaStr(r.name)}",\n`;
            body += `    mode = "${luaStr(r.mode)}",\n`;
            body += `    position = "${Math.round(r.x)}x${Math.round(r.y)}",\n`;
            body += `    scale = ${Number(r.scale) || 1},\n`;
            if (r.disabled)
                body += "    disabled = true,\n";
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

    function ingestDevices(text) {
        try {
            const d = JSON.parse(text);
            const ks = d.keyboards || [];
            let k = null;
            for (let i = 0; i < ks.length; i++) {
                if (ks[i].main) {
                    k = ks[i];
                    break;
                }
            }
            if (!k && ks.length)
                k = ks[0];
            if (!k)
                return;
            const name = `${k.name || ""}`;
            if (name.length)
                root.kbName = name;
            root.layoutName = `${k.active_keymap || ""}`.trim();
        } catch (e) {}
    }

    function refreshLayout() {
        if (!live)
            return;
        layoutProc.running = false;
        Qt.callLater(() => {
            layoutProc.running = true;
        });
    }

    Timer {
        id: occDelay
        interval: 30
        repeat: false
        onTriggered: {
            occProc.running = false;
            actProc.running = false;
            Qt.callLater(() => {
                occProc.running = true;
                actProc.running = true;
            });
        }
    }

    Process {
        id: occProc
        command: ["hyprctl", "clients", "-j"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.ingestClients(text)
        }
    }

    Process {
        id: actProc
        command: ["hyprctl", "monitors", "-j"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.ingestMonitors(text)
        }
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
        command: ["hyprctl", "devices", "-j"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.ingestDevices(text)
        }
    }

    Connections {
        target: Hyprland
        enabled: root.live
        function onRawEvent(event) {
            const n = event.name;
            if (n === "activelayout")
                root.refreshLayout();
            if (n === "openwindow" || n === "closewindow" || n === "movewindow" || n === "movewindowv2" || n === "changefloatingmode" || n === "fullscreen" || n === "activewindow" || n === "windowtitle" || n === "workspace" || n === "createworkspace" || n === "destroyworkspace" || n === "focusedmon") {
                root.scanIdle();
                if (n !== "windowtitle" && n !== "changefloatingmode")
                    root.syncOccupied();
                if (root.overviewOpen)
                    root.syncWindows();
            }
        }
    }

    FileView {
        id: pinFile
        printErrors: false
    }

    onLiveChanged: {
        scanIdle();
        syncOccupied();
        syncWindows();
    }
    onOverviewOpenChanged: syncWindows()

    Component.onCompleted: {
        refreshLayout();
        scanIdle();
        syncOccupied();
    }
}
