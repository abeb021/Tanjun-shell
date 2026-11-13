import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import "../popouts"
import "../sidebar"
import "../widgets"
import "../../services"

Scope {
    Variants {
        model: Quickshell.screens

        Scope {
            id: desk
            required property var modelData

            PanelWindow {
                id: barWin
                screen: desk.modelData
                color: Theme.bg

                readonly property bool vertical: Theme.barVertical
                readonly property string edge: Theme.barEdge

                WlrLayershell.namespace: "tanjun-bar"
                WlrLayershell.layer: WlrLayer.Top

                IdleInhibitor {
                    enabled: !!(Media.player && Media.player.isPlaying)
                    window: barWin
                }

                anchors {
                    top: edge !== "bottom"
                    bottom: edge !== "top"
                    left: edge !== "right"
                    right: edge !== "left"
                }

                implicitWidth: vertical ? Theme.barThickness : 0
                implicitHeight: vertical ? 0 : Theme.barHeight

                property bool draggingBar: false

                function screenAt(global) {
                    const all = Quickshell.screens;
                    if (all) {
                        for (let i = 0; i < all.length; i++) {
                            const s = all[i];
                            if (global.x >= s.x && global.x < s.x + s.width && global.y >= s.y && global.y < s.y + s.height)
                                return s;
                        }
                    }
                    return barWin.screen;
                }

                function pickEdge(x, y, s) {
                    let best = "top";
                    let dist = y;
                    if (s.height - y < dist) {
                        best = "bottom";
                        dist = s.height - y;
                    }
                    if (x < dist) {
                        best = "left";
                        dist = x;
                    }
                    if (s.width - x < dist)
                        best = "right";
                    return best;
                }

                function dragTo(global) {
                    const s = screenAt(global);
                    if (!s)
                        return;
                    const x = Math.max(0, Math.min(s.width, global.x - s.x));
                    const y = Math.max(0, Math.min(s.height, global.y - s.y));
                    UiMode.barDragScreen = `${s.name}`;
                    UiMode.barDragX = x;
                    UiMode.barDragY = y;
                    UiMode.barDragEdge = pickEdge(x, y, s);
                }

                function beginDrag(global) {
                    draggingBar = true;
                    UiMode.barDragging = true;
                    dragTo(global);
                }

                function endDrag() {
                    if (!draggingBar)
                        return;
                    const edge = UiMode.barDragEdge;
                    draggingBar = false;
                    UiMode.barDragging = false;
                    UiMode.barDragEdge = "";
                    UiMode.barDragScreen = "";
                    if (edge.length)
                        Theme.setBarEdge(edge);
                }

                Component.onDestruction: {
                    UiMode.barDragging = false;
                    UiMode.barDragEdge = "";
                }

                Rectangle {
                    width: barWin.vertical ? Theme.barRule : parent.width
                    height: barWin.vertical ? parent.height : Theme.barRule
                    anchors.left: barWin.edge === "right" ? parent.left : undefined
                    anchors.right: barWin.edge === "left" ? parent.right : undefined
                    anchors.top: barWin.edge === "bottom" ? parent.top : undefined
                    anchors.bottom: barWin.edge === "top" ? parent.bottom : undefined
                    color: Theme.barLine
                }

                Item {
                    id: hContent
                    visible: !barWin.vertical
                    anchors.fill: parent
                    opacity: barWin.draggingBar ? 0.25 : 1

                    Behavior on opacity {
                        enabled: Motion.ready
                        NumberAnimation {
                            duration: Motion.fast
                        }
                    }

                    DragHandler {
                        target: null
                        acceptedButtons: Qt.LeftButton
                        grabPermissions: PointerHandler.CanTakeOverFromAnything

                        onActiveChanged: {
                            if (active) {
                                barWin.beginDrag(hContent.mapToGlobal(centroid.position.x, centroid.position.y));
                            } else {
                                if (barWin.draggingBar)
                                    barWin.dragTo(hContent.mapToGlobal(centroid.position.x, centroid.position.y));
                                barWin.endDrag();
                            }
                        }
                        onActiveTranslationChanged: {
                            if (active)
                                barWin.dragTo(hContent.mapToGlobal(centroid.position.x, centroid.position.y));
                        }
                    }

                    Row {
                        id: hLeft
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        LogoBtn {
                            id: hLogoBtn
                        }
                        Workspaces {
                            id: hWorkspaces
                            screenName: barWin.screen && barWin.screen.name ? `${barWin.screen.name}` : ""
                        }
                    }

                    ClockBtn {
                        id: hClockBtn
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        id: hRight
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        LayoutBtn {
                            id: hLayoutBtn
                        }
                        AudioBtn {
                            id: hAudioBtn
                        }
                        NetBtn {
                            id: hNetBtn
                        }
                        NotifyBtn {
                            id: hNotifyBtn
                        }
                        BatteryBtn {
                            id: hBatteryBtn
                        }

                        Repeater {
                            model: SystemTray.items
                            delegate: TrayBtn {}
                        }
                    }
                }

                Item {
                    id: vContent
                    visible: barWin.vertical
                    anchors.fill: parent
                    opacity: barWin.draggingBar ? 0.25 : 1

                    Behavior on opacity {
                        enabled: Motion.ready
                        NumberAnimation {
                            duration: Motion.fast
                        }
                    }

                    DragHandler {
                        target: null
                        acceptedButtons: Qt.LeftButton
                        grabPermissions: PointerHandler.CanTakeOverFromAnything

                        onActiveChanged: {
                            if (active) {
                                barWin.beginDrag(vContent.mapToGlobal(centroid.position.x, centroid.position.y));
                            } else {
                                if (barWin.draggingBar)
                                    barWin.dragTo(vContent.mapToGlobal(centroid.position.x, centroid.position.y));
                                barWin.endDrag();
                            }
                        }
                        onActiveTranslationChanged: {
                            if (active)
                                barWin.dragTo(vContent.mapToGlobal(centroid.position.x, centroid.position.y));
                        }
                    }

                    Column {
                        id: vTop
                        width: parent.width
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2

                        LogoBtn {
                            id: vLogoBtn
                            width: parent.width
                        }
                        Workspaces {
                            id: vWorkspaces
                            vertical: true
                            width: parent.width
                            screenName: barWin.screen && barWin.screen.name ? `${barWin.screen.name}` : ""
                        }
                    }

                    ClockBtn {
                        id: vClockBtn
                        compact: true
                        width: parent.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        id: vBottom
                        width: parent.width
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2

                        LayoutBtn {
                            id: vLayoutBtn
                            width: parent.width
                        }
                        AudioBtn {
                            id: vAudioBtn
                            width: parent.width
                        }
                        NetBtn {
                            id: vNetBtn
                            width: parent.width
                        }
                        NotifyBtn {
                            id: vNotifyBtn
                            width: parent.width
                        }
                        BatteryBtn {
                            id: vBatteryBtn
                            width: parent.width
                            compact: true
                        }

                        Repeater {
                            model: SystemTray.items
                            delegate: TrayBtn {
                                width: Theme.barThickness
                            }
                        }
                    }
                }
            }

            BarDragPreview {
                screenObj: barWin.screen
            }

            LazyLoader {
                id: clockLoad
                // kept alive: a destroyed popout remaps on the next open, and a
                // mapping layer surface is animated by the compositor
                active: true
                BarPop {
                    name: "clock"
                    barWindow: barWin
                    anchorItem: barWin.vertical ? vClockBtn : hClockBtn
                    align: Item.Top
                    source: "CalendarPop.qml"
                }
            }

            LazyLoader {
                id: audioLoad
                // kept alive: a destroyed popout remaps on the next open, and a
                // mapping layer surface is animated by the compositor
                active: true
                BarPop {
                    name: "audio"
                    barWindow: barWin
                    anchorItem: barWin.vertical ? vAudioBtn : hAudioBtn
                    align: Item.TopRight
                    source: "AudioPop.qml"
                }
            }

            LazyLoader {
                id: netLoad
                // kept alive: a destroyed popout remaps on the next open, and a
                // mapping layer surface is animated by the compositor
                active: true
                BarPop {
                    name: "network"
                    barWindow: barWin
                    anchorItem: barWin.vertical ? vNetBtn : hNetBtn
                    align: Item.TopRight
                    source: "NetPop.qml"
                }
            }

            LazyLoader {
                id: notifyLoad
                // kept alive: a destroyed popout remaps on the next open, and a
                // mapping layer surface is animated by the compositor
                active: true
                BarPop {
                    name: "notify"
                    barWindow: barWin
                    anchorItem: barWin.vertical ? vNotifyBtn : hNotifyBtn
                    align: Item.TopRight
                    source: "NotifyPop.qml"
                }
            }

            LazyLoader {
                id: batteryLoad
                // kept alive: a destroyed popout remaps on the next open, and a
                // mapping layer surface is animated by the compositor
                active: true
                BarPop {
                    name: "battery"
                    barWindow: barWin
                    anchorItem: barWin.vertical ? vBatteryBtn : hBatteryBtn
                    align: Item.TopRight
                    source: "BatteryPop.qml"
                }
            }

            LazyLoader {
                id: trayLoad
                // kept alive: a destroyed popout remaps on the next open, and a
                // mapping layer surface is animated by the compositor
                active: true
                BarPop {
                    name: "tray"
                    barWindow: barWin
                    anchorItem: UiMode.popoutAnchor || (barWin.vertical ? vBatteryBtn : hBatteryBtn)
                    align: Item.TopRight
                    source: "TrayPop.qml"
                }
            }

            LazyLoader {
                id: sideLoad
                active: UiMode.sidebarReady
                Sidebar {
                    barWindow: barWin
                }
            }
        }
    }
}
