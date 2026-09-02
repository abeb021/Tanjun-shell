import QtQuick
import Quickshell
import "../bar"
import "../../services"

Rectangle {
    color: Theme.surface
    border.width: 1
    border.color: Theme.bg
    radius: Theme.radius
    implicitWidth: 220
    implicitHeight: col.implicitHeight + 16

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 8

        BarText {
            text: Battery.charging ? "charging" : "battery"
            px: 12
        }
        BarText {
            text: `${Battery.percent}%`
            px: 22
            color: Battery.percent <= 15 ? Theme.critical : Theme.fg
        }
        Rectangle {
            width: parent.width
            height: 8
            color: Theme.bg
            Rectangle {
                width: parent.width * Battery.percent / 100
                height: parent.height
                color: Battery.percent <= 15 ? Theme.critical : Theme.accent
            }
        }
    }
}
