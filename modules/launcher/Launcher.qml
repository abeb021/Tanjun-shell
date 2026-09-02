import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../bar"
import "../../services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: ShellState.launcherOpen || card.opacity > 0.02
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            focusable: true

            readonly property bool open: ShellState.launcherOpen
            readonly property string raw: query.text
            readonly property string mode: {
                const t = raw;
                if (t.startsWith("="))
                    return "calc";
                if (t.startsWith(";"))
                    return "clip";
                if (t.startsWith("?"))
                    return "web";
                if (t.startsWith("/"))
                    return "act";
                if (t.startsWith("@"))
                    return "music";
                return "apps";
            }
            readonly property string body: mode === "apps" ? raw : raw.slice(1).trim()
            property string calcOut: ""
            property var clipLines: []

            WlrLayershell.namespace: "tanjun-launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            onOpenChanged: if (open) {
                query.text = "";
                query.forceActiveFocus();
            }

            Shortcut {
                sequence: "Escape"
                enabled: open
                onActivated: ShellState.closeMenus()
            }

            MouseArea {
                anchors.fill: parent
                enabled: open
                onClicked: ShellState.closeMenus()
            }

            Rectangle {
                id: card
                width: 560
                height: Math.min(parent.height * 0.72, query.text.length ? 520 : 460)
                anchors.centerIn: parent
                color: Theme.bg
                border.width: 1
                border.color: Theme.accent
                radius: Theme.radius
                opacity: open ? 1 : 0
                scale: open ? 1 : Motion.panelFrom

                Behavior on opacity {
                    enabled: Motion.ready
                    NumberAnimation {
                        duration: Motion.panel
                        easing.type: open ? Motion.easeOut : Motion.easeIn
                    }
                }
                Behavior on scale {
                    enabled: Motion.ready
                    NumberAnimation {
                        duration: Motion.panel
                        easing.type: open ? Motion.easeOut : Motion.easeIn
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Row {
                        spacing: 10
                        BarText {
                            text: "単"
                            family: Theme.fontJp
                            px: 22
                            color: Theme.accent
                        }
                        Rectangle {
                            width: 480
                            height: 28
                            color: Theme.surface
                            border.width: 1
                            border.color: Theme.accent
                            radius: Theme.radius
                            TextInput {
                                id: query
                                anchors.fill: parent
                                anchors.margins: 4
                                font.family: Theme.fontUi
                                font.pixelSize: 14
                                color: Theme.fg
                                clip: true
                                Keys.onEscapePressed: ShellState.closeMenus()
                                Keys.onDownPressed: {
                                    if (results.filtered.length === 0)
                                        return;
                                    results.currentIndex = Math.min(results.filtered.length - 1, results.currentIndex + 1);
                                }
                                Keys.onUpPressed: {
                                    if (results.filtered.length === 0)
                                        return;
                                    results.currentIndex = Math.max(0, results.currentIndex - 1);
                                }
                                Keys.onReturnPressed: win.activate()
                                Keys.onEnterPressed: win.activate()
                                onTextChanged: {
                                    results.currentIndex = 0;
                                    if (win.mode === "calc")
                                        calcTimer.restart();
                                }
                            }
                        }
                    }

                    RestCard {
                        visible: query.text.length === 0
                        width: parent.width
                        height: parent.height - 52
                    }

                    ListView {
                        id: results
                        visible: query.text.length > 0
                        width: parent.width
                        height: parent.height - 52
                        clip: true
                        property var filtered: {
                            win.calcOut;
                            win.clipLines;
                            win.mode;
                            win.body;
                            Media.line;
                            Media.active;
                            ShellState.dnd;
                            return win.rows();
                        }
                        model: filtered
                        currentIndex: 0
                        highlightMoveDuration: 0
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: results.width
                            height: 40
                            color: results.currentIndex === index || ma.containsMouse ? Theme.surfaceHover : "transparent"
                            radius: Theme.radius
                            border.width: results.currentIndex === index ? 1 : 0
                            border.color: Theme.accent
                            BarText {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                width: parent.width - 16
                                text: modelData.name
                                px: 13
                                color: modelData.kind === "hint" ? Theme.fgSub : Theme.fg
                            }
                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    results.currentIndex = index;
                                    win.activateAt(index);
                                }
                            }
                        }
                    }
                }
            }

            Timer {
                id: calcTimer
                interval: 140
                onTriggered: {
                    if (win.mode === "calc" && win.body.length) {
                        calcProc.running = false;
                        calcProc.running = true;
                    } else {
                        win.calcOut = "";
                    }
                }
            }

            Process {
                id: calcProc
                command: ["bash", `${Quickshell.shellDir}/scripts/tanjun-calc.sh`, win.body]
                stdout: StdioCollector {
                    onStreamFinished: win.calcOut = text.trim()
                }
            }

            Process {
                id: clipProc
                running: win.open && win.mode === "clip"
                command: ["cliphist", "list"]
                stdout: StdioCollector {
                    onStreamFinished: win.clipLines = text.split("\n").filter(l => l.length)
                }
            }

            function rows() {
                const mode = win.mode;
                const q = win.body;
                const out = [];
                if (mode === "calc") {
                    win.calcOut;
                    if (!q.length)
                        out.push({ kind: "hint", name: "type an expression" });
                    else if (win.calcOut.length)
                        out.push({ kind: "calc", name: win.calcOut, value: win.calcOut });
                    else
                        out.push({ kind: "hint", name: "…" });
                    return out;
                }
                if (mode === "clip") {
                    const lines = win.clipLines;
                    const low = q.toLowerCase();
                    for (let i = 0; i < lines.length && out.length < 30; i++) {
                        const line = lines[i];
                        const preview = line.indexOf("\t") >= 0 ? line.slice(line.indexOf("\t") + 1) : line;
                        if (low.length && preview.toLowerCase().indexOf(low) < 0 && line.toLowerCase().indexOf(low) < 0)
                            continue;
                        out.push({ kind: "clip", name: preview, line: line });
                    }
                    if (!out.length)
                        out.push({ kind: "hint", name: q.length ? "no clips" : "no clipboard history" });
                    return out;
                }
                if (mode === "web") {
                    if (!q.length) {
                        out.push({ kind: "hint", name: "type a search or url" });
                        return out;
                    }
                    const url = /^https?:\/\//i.test(q) || (/^[a-z0-9.-]+\.[a-z]{2,}/i.test(q) && q.indexOf(" ") < 0);
                    if (url)
                        out.push({ kind: "web", name: "open  " + q, url: /^https?:\/\//i.test(q) ? q : `https://${q}` });
                    out.push({ kind: "web", name: "search  " + q, url: `https://duckduckgo.com/?q=${encodeURIComponent(q)}` });
                    return out;
                }
                if (mode === "act") {
                    const acts = [
                        { kind: "act", name: "lock", id: "lock" },
                        { kind: "act", name: "logout", id: "logout" },
                        { kind: "act", name: "reboot", id: "reboot" },
                        { kind: "act", name: "sleep", id: "sleep" },
                        { kind: "act", name: ShellState.dnd ? "do not disturb · off" : "do not disturb · on", id: "dnd" },
                        { kind: "act", name: "clipboard", id: "clipboard" },
                        { kind: "act", name: "system", id: "sidebar" }
                    ];
                    const low = q.toLowerCase();
                    for (let i = 0; i < acts.length; i++) {
                        if (!low.length || acts[i].name.toLowerCase().indexOf(low) >= 0 || acts[i].id.indexOf(low) >= 0)
                            out.push(acts[i]);
                    }
                    if (!out.length)
                        out.push({ kind: "hint", name: "no actions" });
                    return out;
                }
                if (mode === "music") {
                    if (Media.active) {
                        out.push({ kind: "music", name: (Media.player && Media.player.isPlaying ? "pause  " : "play  ") + (Media.line || "now"), id: "toggle" });
                        out.push({ kind: "music", name: "next", id: "next" });
                        out.push({ kind: "music", name: "previous", id: "prev" });
                    }
                    if (q.length)
                        out.push({ kind: "music", name: "spotify  " + q, id: "search", query: q });
                    else if (!out.length)
                        out.push({ kind: "hint", name: "nothing playing · type to search spotify" });
                    return out;
                }
                const apps = DesktopEntries.applications.values;
                const low = q.toLowerCase();
                if (apps) {
                    for (let i = 0; i < apps.length && out.length < 30; i++) {
                        const a = apps[i];
                        if (a.noDisplay)
                            continue;
                        const n = (a.name || "").toLowerCase();
                        if (!low || n.indexOf(low) >= 0)
                            out.push({ kind: "app", name: a.name, entry: a });
                    }
                }
                if (!out.length)
                    out.push({ kind: "hint", name: "no apps" });
                return out;
            }

            function activate() {
                if (results.filtered.length === 0)
                    return;
                activateAt(Math.max(0, results.currentIndex));
            }

            function activateAt(index) {
                const row = results.filtered[index];
                if (!row || row.kind === "hint")
                    return;
                if (row.kind === "app") {
                    try {
                        row.entry.execute();
                    } catch (e) {
                        Quickshell.execDetached(["gtk-launch", row.entry.id]);
                    }
                    ShellState.launcherOpen = false;
                    return;
                }
                if (row.kind === "calc") {
                    Quickshell.execDetached(["wl-copy", row.value]);
                    ShellState.launcherOpen = false;
                    return;
                }
                if (row.kind === "clip") {
                    const line = row.line.replace(/'/g, "'\\''");
                    Quickshell.execDetached(["bash", "-c", `printf '%s\\n' '${line}' | cliphist decode | wl-copy`]);
                    ShellState.launcherOpen = false;
                    return;
                }
                if (row.kind === "web") {
                    Quickshell.execDetached(["xdg-open", row.url]);
                    ShellState.launcherOpen = false;
                    return;
                }
                if (row.kind === "act") {
                    runAct(row.id);
                    return;
                }
                if (row.kind === "music") {
                    if (row.id === "toggle" && Media.player)
                        Media.player.togglePlaying();
                    else if (row.id === "next" && Media.player && Media.player.canGoNext)
                        Media.player.next();
                    else if (row.id === "prev" && Media.player && Media.player.canGoPrevious)
                        Media.player.previous();
                    else if (row.id === "search")
                        Quickshell.execDetached(["xdg-open", `https://open.spotify.com/search/${encodeURIComponent(row.query)}`]);
                    if (row.id === "search")
                        ShellState.launcherOpen = false;
                }
            }

            function runAct(id) {
                if (id === "lock") {
                    ShellState.closeMenus();
                    const cmd = Config.argv(Config.session.lock);
                    if (cmd.length)
                        Quickshell.execDetached(cmd);
                    return;
                }
                if (id === "logout") {
                    ShellState.closeMenus();
                    Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
                    return;
                }
                if (id === "reboot") {
                    ShellState.closeMenus();
                    Quickshell.execDetached(["systemctl", "reboot"]);
                    return;
                }
                if (id === "sleep") {
                    ShellState.closeMenus();
                    Quickshell.execDetached(["systemctl", "suspend"]);
                    return;
                }
                if (id === "dnd") {
                    ShellState.dnd = !ShellState.dnd;
                    ShellState.closeMenus();
                    return;
                }
                if (id === "clipboard") {
                    ShellState.closeMenus();
                    ShellState.toggleClipboard();
                    return;
                }
                if (id === "sidebar") {
                    ShellState.closeMenus();
                    ShellState.toggleSidebar();
                }
            }
        }
    }
}
