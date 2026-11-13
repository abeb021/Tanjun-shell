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
                property real dragStartX: 0
                property real dragStartY: 0

                // A layer surface anchored to the right or bottom edge is placed
                // by the compositor, but Qt keeps the position the window was
                // mapped with, so mapToGlobal reports the screen's top-left for
                // those and the drag ends up glued to the wrong wall. The real
                // origin follows from the edge and the screen size instead.
                function screenPoint(local) {
                    const s = barWin.screen;
                    if (!s || !local)
                        return null;
                    const ox = barWin.edge === "right" ? s.width - barWin.width : 0;
                    const oy = barWin.edge === "bottom" ? s.height - barWin.height : 0;
                    return {
                        x: Math.max(0, Math.min(s.width, ox + local.x)),
                        y: Math.max(0, Math.min(s.height, oy + local.y))
                    };
                }

                // The bar lands on the border the pointer is brought to: a third
                // of the screen at either end of the bar picks that side, the
                // middle third picks the border opposite the current one as soon
                // as the pointer is carried off the bar. Comparing distances all
                // the way to the far border would make the near one unbeatable,
                // which is why sideways moves used to do nothing at all.
                function pickEdge(x, y, s) {
                    const bar = Theme.barThickness;
                    const vertical = barWin.vertical;
                    const along = vertical ? y : x;
                    const span = vertical ? s.height : s.width;

                    if (along < span / 3)
                        return vertical ? "top" : "left";
                    if (along > span * 2 / 3)
                        return vertical ? "bottom" : "right";

                    const offBar = vertical
                        ? (Theme.barEdge === "left" ? x > bar : s.width - x > bar)
                        : (Theme.barEdge === "top" ? y > bar : s.height - y > bar);
                    if (!offBar)
                        return Theme.barEdge;
                    if (vertical)
                        return Theme.barEdge === "left" ? "right" : "left";
                    return Theme.barEdge === "top" ? "bottom" : "top";
                }

                function dragTo(local) {
                    const point = screenPoint(local);
                    if (!point)
                        return;
                    UiMode.barDragScreen = `${barWin.screen.name}`;
                    UiMode.barDragX = point.x;
                    UiMode.barDragY = point.y;
                    // a real drag has to happen before the bar switches border,
                    // so taking hold of it never flips it
                    const moved = Math.max(Math.abs(point.x - dragStartX), Math.abs(point.y - dragStartY));
                    if (moved >= 24)
                        UiMode.barDragEdge = pickEdge(point.x, point.y, barWin.screen);
                }

                function beginDrag(local) {
                    const point = screenPoint(local);
                    if (!point)
                        return;
                    // a menu hanging off the bar would be pinned to the old edge
                    // when the bar lands on a new one
                    UiMode.closeMenus();
                    draggingBar = true;
                    dragStartX = point.x;
                    dragStartY = point.y;
                    UiMode.barDragging = true;
                    UiMode.barDragEdge = Theme.barEdge;
                    dragTo(local);
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
                                barWin.beginDrag(centroid.position);
                            } else {
                                if (barWin.draggingBar)
                                    barWin.dragTo(centroid.position);
                                barWin.endDrag();
                            }
                        }
                        onActiveTranslationChanged: {
                            if (active)
                                barWin.dragTo(centroid.position);
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
                                barWin.beginDrag(centroid.position);
                            } else {
                                if (barWin.draggingBar)
                                    barWin.dragTo(centroid.position);
                                barWin.endDrag();
                            }
                        }
                        onActiveTranslationChanged: {
                            if (active)
                                barWin.dragTo(centroid.position);
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
