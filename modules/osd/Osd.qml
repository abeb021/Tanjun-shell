import QtQuick
import Quickshell
import "../bar"
import "../../services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: ShellState.osdKind.length > 0
            color: "transparent"
            implicitWidth: 220
            implicitHeight: 52
            exclusionMode: ExclusionMode.Ignore

            anchors {
                bottom: true
            }
            margins.bottom: 48

            Rectangle {
                anchors.fill: parent
                color: Theme.surface
                border.width: 1
                border.color: Theme.accent
                radius: Theme.radius

                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    BarText {
                        text: ShellState.osdKind === "brightness" ? "󰃠" : (Audio.muted ? "" : "")
                        icon: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Rectangle {
                        width: 180
                        height: 6
                        color: Theme.bg
                        Rectangle {
                            width: parent.width * ShellState.osdValue
                            height: parent.height
                            color: Theme.accent
                        }
                    }
                }
            }
        }
    }
}
