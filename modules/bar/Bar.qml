import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import "../popouts"
import "../../services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWin
            required property var modelData
            screen: modelData
            color: Theme.bg
            implicitHeight: Theme.barHeight

            WlrLayershell.namespace: "tanjun-bar"
            WlrLayershell.layer: WlrLayer.Top

            anchors {
                top: true
                left: true
                right: true
            }

            Row {
                id: left
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 4
                spacing: 2

                LogoBtn {}
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
                anchors.rightMargin: 4
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
                    delegate: BarButton {
                        required property var modelData
                        implicitWidth: 22
                        onClicked: modelData.activate()
                        onRightClicked: modelData.secondaryActivate()
                        Image {
                            source: modelData.icon
                            sourceSize.width: 16
                            sourceSize.height: 16
                            width: 16
                            height: 16
                        }
                    }
                }
            }

            BarPop {
                name: "clock"
                barWindow: barWin
                anchorItem: clockBtn
                implicitWidth: cal.implicitWidth
                implicitHeight: cal.implicitHeight
                CalendarPop {
                    id: cal
                }
            }

            BarPop {
                name: "audio"
                barWindow: barWin
                anchorItem: audioBtn
                implicitWidth: ap.implicitWidth
                implicitHeight: ap.implicitHeight
                AudioPop {
                    id: ap
                }
            }

            BarPop {
                name: "network"
                barWindow: barWin
                anchorItem: netBtn
                implicitWidth: np.implicitWidth
                implicitHeight: np.implicitHeight
                NetPop {
                    id: np
                }
            }

            BarPop {
                name: "notify"
                barWindow: barWin
                anchorItem: notifyBtn
                implicitWidth: ntp.implicitWidth
                implicitHeight: ntp.implicitHeight
                NotifyPop {
                    id: ntp
                }
            }

            BarPop {
                name: "battery"
                barWindow: barWin
                anchorItem: batteryBtn
                implicitWidth: bp.implicitWidth
                implicitHeight: bp.implicitHeight
                BatteryPop {
                    id: bp
                }
            }
        }
    }
}
