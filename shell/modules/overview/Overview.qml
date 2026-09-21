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
            open: UiMode.overviewOpen
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
                const focused = Compositor.focusedWorkspaceId;
                const out = [];
                for (let i = 1; i <= 10; i++) {
                    if (i <= 3 || occ[i] || i === focused)
                        out.push(i);
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

            function deskIndexOf(id) {
                const list = desks;
                const n = Number(id) || 0;
                for (let i = 0; i < list.length; i++) {
                    if (Number(list[i]) === n)
                        return i;
                }
                return -1;
            }

            function publishPick() {
                if (!isFocused)
                    return;
                if (!open) {
                    UiMode.overviewPick = "";
                    UiMode.overviewCount = 0;
                    return;
                }
                const list = windows;
                UiMode.overviewCount = list.length;
                const w = list[currentIndex];
                UiMode.overviewPick = w ? `${w.addr || ""}` : "";
            }

            function revealPick() {
                const w = windows[currentIndex];
                if (!w)
                    return;
                const i = deskIndexOf(w.workspaceId);
                if (i >= 0)
                    scroller.positionViewAtIndex(i, ListView.Contain);
            }

            function addrIndex(addr) {
                const list = windows;
                const a = `${addr || ""}`;
                for (let i = 0; i < list.length; i++) {
                    if (`${list[i].addr || ""}` === a)
                        return i;
                }
                return -1;
            }

            function selectAddr(addr) {
                const i = addrIndex(addr);
                if (i >= 0)
                    currentIndex = i;
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
                    UiMode.closeMenus();
                    return;
                }
                win.pendingAddr = `${w.addr || ""}`;
                win.pendingWs = Number(w.workspaceId) || 0;
                if (w.capture && w.capture.activate)
                    w.capture.activate();
                UiMode.closeMenus();
                goTimer.restart();
            }

            function goDesk(id) {
                win.pendingAddr = "";
                win.pendingWs = id;
                UiMode.closeMenus();
                goTimer.restart();
            }

            onOpenChanged: {
                if (!open) {
                    publishPick();
                    return;
                }
                Compositor.refreshWindows();
                selectActive();
                if (windows.length > 1)
                    win.move(1);
                publishPick();
                Qt.callLater(revealPick);
                if (isFocused)
                    kb.forceActiveFocus();
            }
            onWindowsChanged: {
                clampIndex();
                publishPick();
            }
            onCurrentIndexChanged: {
                publishPick();
                revealPick();
            }

            Connections {
                target: UiMode
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

                ListView {
                    id: scroller
                    anchors.fill: parent
                    clip: true
                    focus: false
                    reuseItems: true
                    cacheBuffer: 480
                    spacing: 22
                    boundsBehavior: Flickable.StopAtBounds
                    model: win.desks
                    delegate: Column {
                                id: desk
                                required property var modelData
                                spacing: 8

                                readonly property int deskId: Number(modelData)
                                readonly property int tileCount: {
                                    const all = win.windows;
                                    const id = desk.deskId;
                                    let n = 0;
                                    for (let i = 0; i < all.length; i++) {
                                        if (all[i] && Number(all[i].workspaceId) === id)
                                            n++;
                                    }
                                    return n;
                                }
                                readonly property int cardW: 280
                                readonly property int gap: 10
                                readonly property int maxCols: Math.max(1, Math.floor(stage.width / (cardW + gap)))
                                readonly property int cols: tileCount === 0 ? 1 : Math.min(tileCount, maxCols)
                                readonly property bool hasPick: {
                                    const w = win.windows[win.currentIndex];
                                    return !!(w && Number(w.workspaceId) === desk.deskId);
                                }
                                width: tileCount === 0 ? 160 : cols * (cardW + gap) - gap

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
                                        color: desk.hasPick ? Theme.accent : Theme.fgSub
                                    }
                                }

                                Flow {
                                    width: parent.width
                                    spacing: desk.gap

                                    Repeater {
                                        model: ScriptModel {
                                            objectProp: "addr"
                                            values: {
                                                const all = win.windows;
                                                const id = desk.deskId;
                                                const out = [];
                                                for (let i = 0; i < all.length; i++) {
                                                    const w = all[i];
                                                    if (w && Number(w.workspaceId) === id)
                                                        out.push(w);
                                                }
                                                return out;
                                            }
                                        }
                                        delegate: OverviewCard {
                                            required property var modelData
                                            client: modelData
                                            selected: win.addrIndex(`${modelData.addr || ""}`) === win.currentIndex
                                            onClicked: {
                                                win.selectAddr(`${modelData.addr || ""}`);
                                                win.activateCurrent();
                                            }
                                            onHovered: win.selectAddr(`${modelData.addr || ""}`)
                                        }
                                    }

                                    MouseArea {
                                        visible: desk.tileCount === 0
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
                        UiMode.closeMenus();
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
