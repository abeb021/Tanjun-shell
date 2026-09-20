import QtQuick
import "../widgets"
import "../../services"

BarButton {
    id: root
    popoutName: "notify"
    onRightClicked: UiMode.dnd = !UiMode.dnd
    onMiddleClicked: Notifs.clear()
    BarText {
        text: UiMode.dnd ? "" : ""
        icon: true
        px: 13
    }
    Rectangle {
        parent: root.overlay
        visible: Notifs.unread > 0 && !UiMode.dnd
        width: 5
        height: 5
        radius: Theme.radius
        color: Theme.critical
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 6
    }
}
