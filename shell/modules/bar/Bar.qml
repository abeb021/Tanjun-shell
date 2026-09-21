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
                        screen: desk.modelData
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
                active: UiMode.popout === "clock"
                BarPop {
                    name: "clock"
                    barWindow: barWin
                    anchorItem: clockBtn
                    growFrom: Item.Top
                    cardW: cal.implicitWidth
                    cardH: cal.implicitHeight
                    CalendarPop {
                        id: cal
                    }
                }
            }

            LazyLoader {
                id: audioLoad
                active: UiMode.popout === "audio"
                BarPop {
                    name: "audio"
                    barWindow: barWin
                    anchorItem: audioBtn
                    growFrom: Item.TopRight
                    cardW: ap.implicitWidth
                    cardH: ap.implicitHeight
                    AudioPop {
                        id: ap
                    }
                }
            }

            LazyLoader {
                id: netLoad
                active: UiMode.popout === "network"
                BarPop {
                    name: "network"
                    barWindow: barWin
                    anchorItem: netBtn
                    growFrom: Item.TopRight
                    cardW: np.implicitWidth
                    cardH: np.implicitHeight
                    NetPop {
                        id: np
                    }
                }
            }

            LazyLoader {
                id: notifyLoad
                active: UiMode.popout === "notify"
                BarPop {
                    name: "notify"
                    barWindow: barWin
                    anchorItem: notifyBtn
                    growFrom: Item.TopRight
                    cardW: ntp.implicitWidth
                    cardH: ntp.implicitHeight
                    NotifyPop {
                        id: ntp
                    }
                }
            }

            LazyLoader {
                id: batteryLoad
                active: UiMode.popout === "battery"
                BarPop {
                    name: "battery"
                    barWindow: barWin
                    anchorItem: batteryBtn
                    growFrom: Item.TopRight
                    cardW: bp.implicitWidth
                    cardH: bp.implicitHeight
                    BatteryPop {
                        id: bp
                    }
                }
            }

            LazyLoader {
                id: trayLoad
                active: UiMode.popout === "tray"
                BarPop {
                    name: "tray"
                    barWindow: barWin
                    anchorItem: UiMode.popoutAnchor || batteryBtn
                    growFrom: Item.TopRight
                    cardW: tp.implicitWidth
                    cardH: tp.implicitHeight
                    TrayPop {
                        id: tp
                    }
                }
            }

            LazyLoader {
                id: sideLoad
                active: UiMode.sidebarOpen
                Sidebar {
                    barWindow: barWin
                }
            }
        }
    }
}
