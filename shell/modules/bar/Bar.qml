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
                    Workspaces {}
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

            BarPop {
                name: "tray"
                barWindow: barWin
                anchorItem: ShellState.popoutAnchor || batteryBtn
                growFrom: Item.TopRight
                cardW: tp.implicitWidth
                cardH: tp.implicitHeight
                TrayPop {
                    id: tp
                }
            }

            Sidebar {
                barWindow: barWin
            }
        }
    }
}
