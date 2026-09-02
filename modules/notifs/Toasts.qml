import QtQuick
import Quickshell
import Quickshell.Wayland
import "../bar"
import "../../services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: !ShellState.dnd && toast.count > 0
            color: "transparent"
            implicitWidth: 320
            implicitHeight: Math.min(240, toast.count * 64)
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "tanjun-toast"
            WlrLayershell.layer: WlrLayer.Overlay

            anchors {
                top: true
                right: true
            }
            margins.top: Theme.barHeight + 8
            margins.right: 8

            ListView {
                id: toast
                anchors.fill: parent
                model: Notifs.list
                spacing: 6
                delegate: Rectangle {
                    required property var modelData
                    width: toast.width
                    height: 58
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.bg
                    radius: Theme.radius
                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        BarText {
                            text: modelData.summary || modelData.appName
                            px: 12
                            width: parent.width
                        }
                        BarText {
                            text: modelData.body || ""
                            sub: true
                            px: 11
                            width: parent.width
                            elide: Text.ElideRight
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: modelData.dismiss()
                    }
                }
            }
        }
    }
}
