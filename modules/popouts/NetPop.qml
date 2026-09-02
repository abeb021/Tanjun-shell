import QtQuick
import Quickshell
import "../bar"
import "../../services"

Rectangle {
    color: Theme.surface
    border.width: 1
    border.color: Theme.bg
    radius: Theme.radius
    implicitWidth: 240
    implicitHeight: col.implicitHeight + 16

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 8

        BarText {
            text: Net.connected ? Net.ssid : "offline"
            px: 13
        }
        BarText {
            text: "click → nmtui"
            sub: true
            px: 11
        }
        MouseArea {
            width: parent.width
            height: 28
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Quickshell.execDetached(["kitty", "--title=network-manager", "nmtui"]);
                ShellState.closePopout();
            }
            Rectangle {
                anchors.fill: parent
                color: Theme.surfaceHover
                radius: Theme.radius
            }
            BarText {
                anchors.centerIn: parent
                text: "open nmtui"
                px: 12
            }
        }
    }
}
