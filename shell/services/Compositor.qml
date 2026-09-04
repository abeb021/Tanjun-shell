pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property bool isNiri: !!Quickshell.env("NIRI_SOCKET")
    readonly property bool isHypr: !isNiri && !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    readonly property string kind: isNiri ? "niri" : (isHypr ? "hyprland" : "")

    property var niriOccupied: ({})
    property int niriFocusedId: 0
    property string niriFocusedOutput: ""
    property string niriKeymap: ""

    readonly property string focusedOutput: {
        if (isNiri)
            return niriFocusedOutput;
        const m = Hyprland.focusedMonitor;
        return m && m.name ? `${m.name}` : "";
    }

    readonly property int focusedWorkspaceId: {
        if (isNiri)
            return niriFocusedId;
        const ws = Hyprland.focusedWorkspace;
        return ws && ws.id ? ws.id : 0;
    }

    readonly property var occupied: {
        if (isNiri)
            return niriOccupied;
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

    function isScreenFocused(screen) {
        const name = focusedOutput;
        if (!name.length || !screen)
            return true;
        return screen.name === name;
    }

    function activateWorkspace(id) {
        const n = Number(id);
        if (!n)
            return;
        if (isNiri)
            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", `${n}`]);
        else
            Quickshell.execDetached(["hyprctl", "dispatch", "workspace", `${n}`]);
    }

    function moveToWorkspace(id) {
        const n = Number(id);
        if (!n)
            return;
        if (isNiri)
            Quickshell.execDetached(["niri", "msg", "action", "move-window-to-workspace", `${n}`]);
        else
            Quickshell.execDetached(["hyprctl", "dispatch", "movetoworkspace", `${n}`]);
    }

    function cycleWorkspace(delta) {
        if (isNiri) {
            Quickshell.execDetached(["niri", "msg", "action", delta > 0 ? "focus-workspace-up" : "focus-workspace-down"]);
            return;
        }
        Quickshell.execDetached(["hyprctl", "dispatch", "workspace", delta > 0 ? "e-1" : "e+1"]);
    }

    function exitSession() {
        if (isNiri)
            Quickshell.execDetached(["niri", "msg", "action", "quit"]);
        else
            Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
    }

    function toggleOverview() {
        if (isNiri)
            Quickshell.execDetached(["niri", "msg", "action", "toggle-overview"]);
        else
            ShellState.toggleOverview();
    }

    function cycleLayout() {
        if (isNiri) {
            Quickshell.execDetached(["niri", "msg", "action", "switch-layout", "next"]);
            return;
        }
        const quoted = Config.services.keyboard.length ? `'${String(Config.services.keyboard).replace(/'/g, "'\\''")}'` : `"$(${root.hyprKbName})"`;
        Quickshell.execDetached(["bash", "-c", `hyprctl switchxkblayout ${quoted} next`]);
    }

    readonly property string hyprKbName: "hyprctl devices -j | python -c \"import json,sys; d=json.load(sys.stdin); ks=d.get('keyboards',[]); k=next((x for x in ks if x.get('main')), ks[0] if ks else {}); print(k.get('name',''))\""

    function ingestNiriWorkspaces(list) {
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

    function ingestNiriLayouts(obj) {
        if (!obj)
            return;
        const names = obj.names || [];
        const idx = Number(obj.current_idx);
        const t = (idx >= 0 && idx < names.length) ? `${names[idx]}` : "";
        niriKeymap = t;
    }

    function onNiriEvent(line) {
        const s = `${line || ""}`.trim();
        if (!s.length)
            return;
        try {
            const ev = JSON.parse(s);
            if (ev.WorkspacesChanged && ev.WorkspacesChanged.workspaces)
                ingestNiriWorkspaces(ev.WorkspacesChanged.workspaces);
            if (ev.WorkspaceActivated && ev.WorkspaceActivated.focused) {
                niriRefresh.running = false;
                Qt.callLater(() => {
                    niriRefresh.running = true;
                });
            }
            if (ev.KeyboardLayoutsChanged && ev.KeyboardLayoutsChanged.keyboard_layouts)
                ingestNiriLayouts(ev.KeyboardLayoutsChanged.keyboard_layouts);
            if (ev.KeyboardLayoutSwitched) {
                niriLayouts.running = false;
                Qt.callLater(() => {
                    niriLayouts.running = true;
                });
            }
        } catch (e) {}
    }

    Process {
        id: niriRefresh
        command: ["niri", "msg", "--json", "workspaces"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    root.ingestNiriWorkspaces(JSON.parse(text));
                } catch (e) {}
            }
        }
    }

    Process {
        id: niriLayouts
        command: ["niri", "msg", "--json", "keyboard-layouts"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    root.ingestNiriLayouts(JSON.parse(text));
                } catch (e) {}
            }
        }
    }

    Process {
        id: niriEvents
        command: ["niri", "msg", "--json", "event-stream"]
        running: root.isNiri
        stdout: SplitParser {
            onRead: line => root.onNiriEvent(line)
        }
    }

    Component.onCompleted: {
        if (isNiri) {
            niriRefresh.running = true;
            niriLayouts.running = true;
        }
    }
}
