import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../widgets"
import "../../services"

Scope {
    Variants {
        model: Quickshell.screens

        OverlayHost {
            id: win
            required property var modelData
            screen: modelData
            open: UiMode.launcherOpen
            layerName: "tanjun-launcher"
            contentOpacity: card.opacity
            dismissOthers: true

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
            property bool browse: false
            property string rowsBody: ""

            onOpenChanged: {
                browse = false;
                if (open) {
                    query.text = "";
                    rowsBody = "";
                    query.forceActiveFocus();
                }
            }

            Shortcut {
                sequence: "Escape"
                enabled: open
                onActivated: UiMode.closeMenus()
            }

            MouseArea {
                anchors.fill: parent
                enabled: open
                onClicked: UiMode.closeMenus()
            }

                Face {
                    id: card
                    job: "plane"
                    width: 560
                    height: Math.min(parent.height * 0.72, (query.text.length || win.browse) ? 520 : 460)
                    anchors.centerIn: parent
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

                WheelHandler {
                    enabled: win.open
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        const dy = event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y;
                        if (!dy)
                            return;
                        win.nudgeList(dy > 0 ? -1 : 1);
                        event.accepted = true;
                    }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.pad
                    spacing: Theme.gap

                    Rectangle {
                        width: parent.width
                        height: 32
                        color: Theme.surface
                        border.width: 1
                        border.color: query.activeFocus ? Theme.accent : Theme.hairline
                        radius: Theme.radius
                        TextInput {
                            id: query
                            anchors.fill: parent
                            anchors.margins: 6
                            font.family: Theme.fontUi
                            font.pixelSize: Theme.typeBody
                            color: Theme.fg
                            clip: true
                            Keys.onEscapePressed: UiMode.closeMenus()
                            Keys.onDownPressed: win.nudgeList(1)
                            Keys.onUpPressed: win.nudgeList(-1)
                            Keys.onReturnPressed: win.activate()
                            Keys.onEnterPressed: win.activate()
                            onTextChanged: {
                                results.currentIndex = 0;
                                if (query.text.length)
                                    win.browse = false;
                                if (win.mode === "calc")
                                    calcTimer.restart();
                                if (win.mode === "apps")
                                    rowsTimer.restart();
                                else
                                    win.rowsBody = win.body;
                            }
                        }
                    }

                    RestCard {
                        visible: query.text.length === 0 && !win.browse
                        width: parent.width
                        height: parent.height - 52
                    }

                    ListView {
                        id: results
                        visible: query.text.length > 0 || win.browse
                        width: parent.width
                        height: parent.height - 52
                        clip: true
                        reuseItems: true
                        interactive: false
                        boundsBehavior: Flickable.StopAtBounds
                        highlightFollowsCurrentItem: true
                        model: ScriptModel {
                            objectProp: "key"
                            values: {
                                win.calcOut;
                                win.clipLines;
                                win.mode;
                                win.rowsBody;
                                win.browse;
                                win.open;
                                if (win.mode === "apps")
                                    Launches.gen;
                                if (win.mode === "music") {
                                    Media.line;
                                    Media.active;
                                }
                                if (win.mode === "act")
                                    UiMode.dnd;
                                if (!win.open)
                                    return [];
                                if (win.mode === "apps" && query.text.length === 0 && !win.browse)
                                    return [];
                                return win.rows();
                            }
                        }
                        currentIndex: 0
                        highlightMoveDuration: 0
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: results.width
                            height: 40
                            color: results.currentIndex === index || ma.containsMouse ? Theme.surfaceHover : "transparent"
                            radius: Theme.radius
                            Rectangle {
                                visible: results.currentIndex === index
                                width: 1
                                height: parent.height - 10
                                anchors.verticalCenter: parent.verticalCenter
                                color: Theme.accent
                            }
                            readonly property string iconSrc: modelData.kind === "app" ? win.appIcon(modelData.entry) : ""
                            IconImage {
                                id: appIcon
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                implicitSize: iconSrc.length ? 22 : 0
                                visible: iconSrc.length > 0
                                source: iconSrc
                                asynchronous: true
                            }
                            BarText {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: appIcon.visible ? appIcon.right : parent.left
                                anchors.leftMargin: 8
                                anchors.right: parent.right
                                anchors.rightMargin: 8
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
                id: rowsTimer
                interval: 80
                onTriggered: win.rowsBody = win.body
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
                    onStreamFinished: win.clipLines = text.split("\n").filter(l => l.length).slice(0, 40)
                }
            }

            function appIcon(entry) {
                if (!entry)
                    return "";
                const ic = entry.icon || "";
                if (ic.indexOf("/") >= 0)
                    return ic.startsWith("file:") ? ic : ("file://" + ic);
                const name = ic.length ? ic : "application-x-executable";
                const hit = Quickshell.iconPath(name, true);
                if (hit.length)
                    return hit;
                return Quickshell.iconPath("application-x-executable", true);
            }

            function appHay(a) {
                const bits = [a.name || "", a.genericName || "", a.comment || "", a.id || ""];
                try {
                    if (a.keywords && a.keywords.join)
                        bits.push(a.keywords.join(" "));
                } catch (e) {}
                return bits.join(" ").toLowerCase();
            }

            function appMatch(a, low) {
                if (!low.length)
                    return true;
                const name = (a.name || "").toLowerCase();
                if (name.indexOf(low) >= 0)
                    return true;
                const id = (a.id || "").toLowerCase();
                if (id.indexOf(low) >= 0)
                    return true;
                return appHay(a).indexOf(low) >= 0;
            }

            function rowAt(index) {
                const vals = results.model ? results.model.values : null;
                if (!vals || index < 0 || index >= vals.length)
                    return null;
                return vals[index];
            }

            function rows() {
            const q = mode === "apps" ? win.rowsBody : win.body;
                const out = [];
                if (mode === "calc") {
                    win.calcOut;
                    if (!q.length)
                        out.push({ kind: "hint", key: "hint:calc", name: "type an expression" });
                    else if (win.calcOut.length)
                        out.push({ kind: "calc", key: "calc", name: win.calcOut, value: win.calcOut });
                    else
                        out.push({ kind: "hint", key: "hint:wait", name: "…" });
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
                        out.push({ kind: "clip", key: "clip:" + i, name: preview, line: line });
                    }
                    if (!out.length)
                        out.push({ kind: "hint", key: "hint:clip", name: q.length ? "no clips" : "no clipboard history" });
                    return out;
                }
                if (mode === "web") {
                    if (!q.length) {
                        out.push({ kind: "hint", key: "hint:web", name: "type a search or url" });
                        return out;
                    }
                    const url = /^https?:\/\//i.test(q) || (/^[a-z0-9.-]+\.[a-z]{2,}/i.test(q) && q.indexOf(" ") < 0);
                    if (url)
                        out.push({ kind: "web", key: "web:open", name: "open  " + q, url: /^https?:\/\//i.test(q) ? q : `https://${q}` });
                    out.push({ kind: "web", key: "web:search", name: "search  " + q, url: `https://duckduckgo.com/?q=${encodeURIComponent(q)}` });
                    return out;
                }
                if (mode === "act") {
                    const acts = [
                        { kind: "act", key: "act:lock", name: "lock", id: "lock" },
                        { kind: "act", key: "act:logout", name: "logout", id: "logout" },
                        { kind: "act", key: "act:reboot", name: "reboot", id: "reboot" },
                        { kind: "act", key: "act:shutdown", name: "shutdown", id: "shutdown" },
                        { kind: "act", key: "act:dnd", name: UiMode.dnd ? "do not disturb · off" : "do not disturb · on", id: "dnd" },
                        { kind: "act", key: "act:clipboard", name: "clipboard", id: "clipboard" },
                        { kind: "act", key: "act:sidebar", name: "system", id: "sidebar" },
                        { kind: "act", key: "act:settings", name: "settings", id: "settings" }
                    ];
                    const low = q.toLowerCase();
                    for (let i = 0; i < acts.length; i++) {
                        if (!low.length || acts[i].name.toLowerCase().indexOf(low) >= 0 || acts[i].id.indexOf(low) >= 0)
                            out.push(acts[i]);
                    }
                    if (!out.length)
                        out.push({ kind: "hint", key: "hint:act", name: "no actions" });
                    return out;
                }
                if (mode === "music") {
                    if (Media.active) {
                        out.push({ kind: "music", key: "music:toggle", name: (Media.player && Media.player.isPlaying ? "pause  " : "play  ") + (Media.line || "now"), id: "toggle" });
                        out.push({ kind: "music", key: "music:next", name: "next", id: "next" });
                        out.push({ kind: "music", key: "music:prev", name: "previous", id: "prev" });
                    }
                    if (q.length)
                        out.push({ kind: "music", key: "music:search", name: "spotify  " + q, id: "search", query: q });
                    else if (!out.length)
                        out.push({ kind: "hint", key: "hint:music", name: "nothing playing · type to search spotify" });
                    return out;
                }
                const apps = DesktopEntries.applications.values;
                const low = q.toLowerCase();
                if (apps) {
                    for (let i = 0; i < apps.length; i++) {
                        const a = apps[i];
                        if (!a || a.noDisplay)
                            continue;
                        if (!appMatch(a, low))
                            continue;
                        const id = a.id || a.name || `${i}`;
                        out.push({ kind: "app", key: "app:" + id, name: a.name, entry: a });
                    }
                    out.sort((a, b) => {
                        const ia = a.entry && a.entry.id ? a.entry.id : a.name;
                        const ib = b.entry && b.entry.id ? b.entry.id : b.name;
                        const ca = Launches.count(ia);
                        const cb = Launches.count(ib);
                        if (cb !== ca)
                            return cb - ca;
                        const ta = Launches.last(ia);
                        const tb = Launches.last(ib);
                        if (tb !== ta)
                            return tb - ta;
                        if (low.length) {
                            const na = (a.name || "").toLowerCase();
                            const nb = (b.name || "").toLowerCase();
                            const pa = na.startsWith(low) ? 1 : 0;
                            const pb = nb.startsWith(low) ? 1 : 0;
                            if (pb !== pa)
                                return pb - pa;
                        }
                        return (a.name || "").localeCompare(b.name || "");
                    });
                }
                if (!out.length)
                    out.push({ kind: "hint", key: "hint:apps", name: "no apps" });
                return out;
            }

            function nudgeList(dir) {
                if (query.text.length === 0 && win.mode === "apps" && !win.browse) {
                    if (dir > 0) {
                        win.browse = true;
                        results.currentIndex = 0;
                    }
                    return;
                }
                if (results.count === 0)
                    return;
                if (dir > 0) {
                    results.currentIndex = Math.min(results.count - 1, results.currentIndex + 1);
                    return;
                }
                if (win.browse && query.text.length === 0 && results.currentIndex <= 0) {
                    win.browse = false;
                    return;
                }
                results.currentIndex = Math.max(0, results.currentIndex - 1);
            }

            function activate() {
                if (results.count === 0)
                    return;
                activateAt(Math.max(0, results.currentIndex));
            }

            function activateAt(index) {
                const row = rowAt(index);
                if (!row || row.kind === "hint")
                    return;
                if (row.kind === "app") {
                    const id = row.entry && row.entry.id ? row.entry.id : row.name;
                    Launches.bump(id);
                    try {
                        row.entry.execute();
                    } catch (e) {
                        Quickshell.execDetached(["gtk-launch", row.entry.id]);
                    }
                    UiMode.launcherOpen = false;
                    return;
                }
                if (row.kind === "calc") {
                    Quickshell.execDetached(["wl-copy", row.value]);
                    UiMode.launcherOpen = false;
                    return;
                }
                if (row.kind === "clip") {
                    Quickshell.execDetached(["bash", "-c", `printf '%s\\n' ${shellQuote(row.line)} | cliphist decode | wl-copy`]);
                    UiMode.launcherOpen = false;
                    return;
                }
                if (row.kind === "web") {
                    Quickshell.execDetached(["xdg-open", row.url]);
                    UiMode.launcherOpen = false;
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
                        UiMode.launcherOpen = false;
                }
            }

            function shellQuote(s) {
                return "'" + String(s).replace(/'/g, "'\\''") + "'";
            }

            function runAct(id) {
                if (id === "lock") {
                    Lock.request();
                    return;
                }
                if (id === "logout") {
                    UiMode.closeMenus();
                    Compositor.exitSession();
                    return;
                }
                if (id === "reboot") {
                    UiMode.closeMenus();
                    Quickshell.execDetached(["systemctl", "reboot"]);
                    return;
                }
                if (id === "shutdown") {
                    UiMode.closeMenus();
                    Quickshell.execDetached(["systemctl", "poweroff"]);
                    return;
                }
                if (id === "dnd") {
                    UiMode.dnd = !UiMode.dnd;
                    UiMode.closeMenus();
                    return;
                }
                if (id === "clipboard") {
                    UiMode.closeMenus();
                    UiMode.toggleClipboard();
                    return;
                }
                if (id === "sidebar") {
                    UiMode.closeMenus();
                    UiMode.toggleSidebar();
                    return;
                }
                if (id === "settings") {
                    UiMode.closeMenus();
                    UiMode.toggleSettings();
                }
            }
        }
    }
}
