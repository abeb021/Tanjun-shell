import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
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

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: Theme.barHeight

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

            PopupWindow {
                visible: ShellState.popout === "clock"
                grabFocus: true
                anchor.window: barWin
                anchor.item: clockBtn
                implicitWidth: cal.implicitWidth
                implicitHeight: cal.implicitHeight
                color: "transparent"
                CalendarPop {
                    id: cal
                }
            }

            PopupWindow {
                visible: ShellState.popout === "audio"
                grabFocus: true
                anchor.window: barWin
                anchor.item: audioBtn
                implicitWidth: ap.implicitWidth
                implicitHeight: ap.implicitHeight
                color: "transparent"
                AudioPop {
                    id: ap
                }
            }

            PopupWindow {
                visible: ShellState.popout === "network"
                grabFocus: true
                anchor.window: barWin
                anchor.item: netBtn
                implicitWidth: np.implicitWidth
                implicitHeight: np.implicitHeight
                color: "transparent"
                NetPop {
                    id: np
                }
            }

            PopupWindow {
                visible: ShellState.popout === "notify"
                grabFocus: true
                anchor.window: barWin
                anchor.item: notifyBtn
                implicitWidth: ntp.implicitWidth
                implicitHeight: ntp.implicitHeight
                color: "transparent"
                NotifyPop {
                    id: ntp
                }
            }

            PopupWindow {
                visible: ShellState.popout === "battery"
                grabFocus: true
                anchor.window: barWin
                anchor.item: batteryBtn
                implicitWidth: bp.implicitWidth
                implicitHeight: bp.implicitHeight
                color: "transparent"
                BatteryPop {
                    id: bp
                }
            }
        }
    }
}
