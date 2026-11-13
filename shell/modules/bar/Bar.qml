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
                implicitHeight: Theme.barHeight

                WlrLayershell.namespace: "tanjun-bar"
                WlrLayershell.layer: WlrLayer.Top

                IdleInhibitor {
                    enabled: !!(Media.player && Media.player.isPlaying)
                    window: barWin
                }

                anchors {
                    top: true
                    left: true
                    right: true
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Theme.barRule
                    color: Theme.barLine
                }

                Row {
                    id: left
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    LogoBtn {
                        id: logoBtn
                    }
                    Workspaces {
                        screenName: barWin.screen && barWin.screen.name ? `${barWin.screen.name}` : ""
                    }
                }

                ClockBtn {
                    id: clockBtn
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                    id: right
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    LayoutBtn {}
                    AudioBtn {
                        id: audioBtn
                    }
                    NetBtn {
                        id: netBtn
                    }
                    NotifyBtn {
                        id: notifyBtn
                    }
                    BatteryBtn {
                        id: batteryBtn
                    }

                    Repeater {
                        model: SystemTray.items
                        delegate: TrayBtn {}
                    }
                }
            }

            LazyLoader {
                id: clockLoad
                // kept alive: a destroyed popout remaps on the next open, and a
                // mapping layer surface is animated by the compositor
                active: true
                BarPop {
                    name: "clock"
                    barWindow: barWin
                    anchorItem: clockBtn
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
                    anchorItem: audioBtn
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
                    anchorItem: netBtn
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
                    anchorItem: notifyBtn
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
                    anchorItem: batteryBtn
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
                    anchorItem: UiMode.popoutAnchor || batteryBtn
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
