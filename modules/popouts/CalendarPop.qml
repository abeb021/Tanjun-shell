import QtQuick
import Quickshell
import "../bar"
import "../../services"

Rectangle {
    id: root
    color: Theme.surface
    border.width: 1
    border.color: Theme.bg
    radius: Theme.radius
    implicitWidth: 280
    implicitHeight: col.implicitHeight + 16

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 8

        BarText {
            text: Time.date
            px: 12
        }
        BarText {
            text: Time.timeFull
            px: 28
        }
        BarText {
            text: "Europe/Moscow"
            sub: true
            px: 11
        }
        Rectangle {
            width: parent.width
            height: 1
            color: Theme.bg
        }
        BarText {
            text: Qt.formatDateTime(Time.now, "MMMM yyyy")
            px: 12
        }
    }
}
