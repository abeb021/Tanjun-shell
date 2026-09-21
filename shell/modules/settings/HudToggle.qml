import QtQuick
import "../../services"

Rectangle {
    id: root

    property bool on: false

    implicitWidth: 44
    implicitHeight: 22
    width: implicitWidth
    height: implicitHeight
    radius: Theme.radius
    color: on ? Theme.accent : Theme.surface
    border.width: 1
    border.color: Theme.hairline

    signal toggled

    Rectangle {
        width: 16
        height: 16
        radius: Theme.radius
        color: root.on ? Theme.bg : Theme.fg
        anchors.verticalCenter: parent.verticalCenter
        x: root.on ? parent.width - width - 3 : 3
        Behavior on x {
            enabled: Motion.ready
            NumberAnimation {
                duration: Motion.fast
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
