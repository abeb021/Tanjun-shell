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
        spacing: 10

        BarText {
            text: Audio.muted ? "muted" : `${Math.round(Audio.volume * 100)}%`
            px: 12
        }

        Rectangle {
            width: parent.width
            height: 8
            radius: 1
            color: Theme.bg
            Rectangle {
                width: parent.width * Audio.volume
                height: parent.height
                color: Audio.muted ? Theme.critical : Theme.accent
            }
            MouseArea {
                anchors.fill: parent
                onClicked: mouse => Audio.setVolume(mouse.x / width)
            }
        }

        Row {
            spacing: 8
            BarButton {
                implicitWidth: 72
                onClicked: Audio.toggleMute()
                BarText {
                    text: Audio.muted ? "unmute" : "mute"
                    px: 11
                }
            }
        }
    }
}
