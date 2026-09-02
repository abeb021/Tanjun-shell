import QtQuick
import Quickshell
import "../../services"

BarButton {
    id: root
    popoutName: "notify"
    onRightClicked: ShellState.dnd = !ShellState.dnd
    onMiddleClicked: Notifs.clear()
    BarText {
        text: ShellState.dnd ? "" : ""
        icon: true
        px: 13
    }
    Rectangle {
        visible: Notifs.unread > 0 && !ShellState.dnd
        width: 6
        height: 6
        radius: 3
        color: Theme.critical
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 4
    }
}
