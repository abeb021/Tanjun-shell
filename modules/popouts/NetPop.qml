import QtQuick
import Quickshell
import Quickshell.Networking
import "../widgets"
import "../../services"

Rectangle {
    color: Theme.surface
    border.width: 1
    border.color: Theme.hairline
    radius: Theme.radius
    implicitWidth: 260
    implicitHeight: col.implicitHeight + 16
    focus: true
    Keys.onEscapePressed: ShellState.closeMenus()

    Connections {
        target: ShellState
        function onPopoutChanged() {
            Net.setScanning(ShellState.popout === "network");
        }
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 8

        Row {
            spacing: 8
            BarText {
                text: Net.connected ? Net.ssid : (Net.wifiOn ? "wifi" : "offline")
                px: 13
            }
        }

        BarText {
            visible: Net.vpnUp
            text: "vpn  " + Net.vpn
            px: 12
            color: Theme.accent
        }

        BarButton {
            implicitWidth: parent.width
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
            BarText {
                text: Net.wifiOn ? "wifi · on" : "wifi · off"
                px: 11
            }
        }

        Repeater {
            model: Net.networks
            delegate: BarButton {
                required property var modelData
                implicitWidth: col.width
                active: modelData.connected
                onClicked: {
                    if (modelData.connected)
                        modelData.disconnect();
                    else
                        modelData.connect();
                }
                BarText {
                    text: (modelData.connected ? "● " : "○ ") + (modelData.name || "hidden")
                    px: 12
                    color: modelData.connected ? Theme.accent : Theme.fg
                    width: col.width - 16
                    elide: Text.ElideRight
                }
            }
        }
    }
}
