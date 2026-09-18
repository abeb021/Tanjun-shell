import QtQuick
import Quickshell
import Quickshell.Wayland
import "../widgets"
import "../../services"

Scope {
    Variants {
        model: Quickshell.screens

        OverlayHost {
            id: win
            required property var modelData
            screen: modelData
            open: ShellState.overviewOpen
            layerName: "tanjun-overview"
            grabKeys: Compositor.isScreenFocused(modelData)
            contentOpacity: stage.opacity
            dismissOthers: false

            readonly property bool isFocused: Compositor.isScreenFocused(modelData)
            readonly property string outputName: modelData && modelData.name ? `${modelData.name}` : ""
            readonly property var desks: {
                if (!win.open)
                    return [];
                const occ = Compositor.occupied || {};
                const out = [];
                for (let i = 1; i <= 10; i++) {
                    if (i <= 3 || occ[i])
                        out.push({
                            id: i
                        });
                }
                return out;
            }
            readonly property var windows: {
                if (!win.open)
                    return [];
                const list = Compositor.windows || [];
                const out = [];
                for (let i = 0; i < list.length; i++) {
                    const w = list[i];
                    if (!w)
                        continue;
                    const id = Number(w.workspaceId) || 0;
                    if (id < 1 || id > 10)
                        continue;
                    if (win.outputName.length && w.output && `${w.output}` !== win.outputName)
                        continue;
                    out.push(w);
                }
                out.sort((a, b) => {
                    const wa = Number(a.workspaceId) || 99;
                    const wb = Number(b.workspaceId) || 99;
                    if (wa !== wb)
                        return wa - wb;
                    return `${a.addr || ""}`.localeCompare(`${b.addr || ""}`);
                });
                return out;
            }
            property int currentIndex: 0
            property string pendingAddr: ""
            property int pendingWs: 0

            Timer {
                id: goTimer
                interval: 40
                repeat: false
                onTriggered: {
                    if (win.pendingWs > 0)
                        Compositor.activateWorkspace(win.pendingWs);
                    if (win.pendingAddr.length)
                        Compositor.focusWindow(win.pendingAddr);
                    win.pendingAddr = "";
                    win.pendingWs = 0;
                }
            }

            function clampIndex() {
                const n = windows.length;
                if (n === 0) {
                    currentIndex = 0;
                    return;
                }
                currentIndex = Math.max(0, Math.min(n - 1, currentIndex));
            }

            function selectActive() {
                const list = windows;
                for (let i = 0; i < list.length; i++) {
                    if (list[i].activated) {
                        currentIndex = i;
                        return;
                    }
                }
                currentIndex = 0;
            }

            function move(delta) {
                const n = windows.length;
                if (n === 0)
                    return;
                currentIndex = (currentIndex + delta % n + n) % n;
            }

            function activateCurrent() {
                const w = windows[currentIndex];
                if (!w) {
                    ShellState.closeMenus();
                    return;
                }
                win.pendingAddr = `${w.addr || ""}`;
                win.pendingWs = Number(w.workspaceId) || 0;
                if (w.capture && w.capture.activate)
                    w.capture.activate();
                ShellState.closeMenus();
                goTimer.restart();
            }

            function goDesk(id) {
                win.pendingAddr = "";
                win.pendingWs = id;
                ShellState.closeMenus();
                goTimer.restart();
            }

            onOpenChanged: {
                if (!open)
                    return;
                Compositor.refreshWindows();
                selectActive();
                if (windows.length > 1)
                    win.move(1);
                if (isFocused)
                    kb.forceActiveFocus();
            }
            onWindowsChanged: clampIndex()

            Connections {
                target: ShellState
                function onOverviewNudgeChanged() {
                    if (win.open)
                        win.move(1);
                }
                function onOverviewCommitChanged() {
                    if (win.open)
                        win.activateCurrent();
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.bg
                opacity: win.open ? 0.62 : 0
                Behavior on opacity {
                    enabled: Motion.ready
                    NumberAnimation {
                        duration: Motion.peek
                        easing.type: win.open ? Motion.easeOut : Motion.easeIn
                    }
                }
            }

            Item {
                id: stage
                anchors.fill: parent
                anchors.margins: 28
                opacity: win.open ? 1 : 0
                Behavior on opacity {
                    enabled: Motion.ready
                    NumberAnimation {
                        duration: Motion.peek
                        easing.type: win.open ? Motion.easeOut : Motion.easeIn
                    }
                }

                Flickable {
                    id: scroller
                    anchors.fill: parent
                    clip: true
                    focus: false
                    boundsBehavior: Flickable.StopAtBounds
                    contentWidth: width
                    contentHeight: Math.max(height, col.implicitHeight + 1)

                    Column {
                        id: col
                        x: Math.max(0, (scroller.width - width) / 2)
                        y: Math.max(0, (scroller.height - implicitHeight) / 2)
                        spacing: 22

                        Repeater {
                            model: win.desks
                            delegate: Column {
                                id: desk
                                required property var modelData
                                spacing: 8

                                readonly property int deskId: modelData.id
                                readonly property var tiles: {
                                    const all = win.windows;
                                    const out = [];
                                    for (let i = 0; i < all.length; i++) {
                                        const w = all[i];
                                        if (Number(w.workspaceId) === desk.deskId)
                                            out.push({
                                                tl: w,
                                                index: i
                                            });
                                    }
                                    return out;
                                }
                                readonly property int cardW: 280
                                readonly property int gap: 10
                                readonly property int maxCols: Math.max(1, Math.floor(stage.width / (cardW + gap)))
                                readonly property int cols: tiles.length === 0 ? 1 : Math.min(tiles.length, maxCols)
                                width: tiles.length === 0 ? 160 : cols * (cardW + gap) - gap

                                MouseArea {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: numLab.implicitWidth + 10
                                    height: 22
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.goDesk(desk.deskId)
                                    BarText {
                                        id: numLab
                                        anchors.centerIn: parent
                                        text: `${desk.deskId}`
                                        role: "title"
                                        color: Compositor.focusedWorkspaceId === desk.deskId ? Theme.accent : Theme.fgSub
                                    }
                                }

                                Flow {
                                    width: parent.width
                                    spacing: desk.gap

                                    Repeater {
                                        model: desk.tiles
                                        delegate: OverviewCard {
                                            required property var modelData
                                            client: modelData.tl
                                            selected: win.currentIndex === modelData.index
                                            onClicked: {
                                                win.currentIndex = modelData.index;
                                                win.activateCurrent();
                                            }
                                            onHovered: win.currentIndex = modelData.index
                                        }
                                    }

                                    MouseArea {
                                        visible: desk.tiles.length === 0
                                        width: 160
                                        height: 100
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: win.goDesk(desk.deskId)
                                        Rectangle {
                                            anchors.fill: parent
                                            color: "transparent"
                                            border.width: 1
                                            border.color: Theme.hairline
                                            radius: Theme.radius
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: kb
                anchors.fill: parent
                focus: win.open && win.isFocused
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: event => {
                    if (!win.open || !win.isFocused)
                        return;
                    const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
                    if (event.key === Qt.Key_Escape) {
                        ShellState.closeMenus();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_J || event.key === Qt.Key_L) {
                        win.move(shift ? -1 : 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_K || event.key === Qt.Key_H) {
                        win.move(-1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        win.activateCurrent();
                        event.accepted = true;
                    } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                        win.goDesk(event.key - Qt.Key_0);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_0) {
                        win.goDesk(10);
                        event.accepted = true;
                    }
                }
                Keys.onReleased: event => {
                    if (!win.open || !win.isFocused)
                        return;
                    if (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R) {
                        win.activateCurrent();
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
