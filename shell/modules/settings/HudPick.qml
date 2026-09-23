import QtQuick
import "../widgets"
import "../../services"

Rectangle {
    id: root

    property string label: ""
    property bool current: false

    implicitHeight: 42
    implicitWidth: Math.max(42, lab.implicitWidth + 24)
    height: implicitHeight
    radius: Theme.radius
    color: current || hover.containsMouse ? Theme.hotSoft : "transparent"
    border.width: Theme.chipBorder
    border.color: current || hover.containsMouse ? Theme.accent : Theme.hairline
    Behavior on color {
        enabled: Motion.ready
        ColorAnimation {
            duration: Motion.fast
        }
    }
    Behavior on border.color {
        enabled: Motion.ready
        ColorAnimation {
            duration: Motion.fast
        }
    }

    signal clicked

    BarText {
        id: lab
        anchors.centerIn: parent
        text: root.label
        px: 10
        family: Config.defaultFontUi
        font.letterSpacing: Theme.chipTracking
        color: root.current ? Theme.accent : Theme.fg
    }

    Rectangle {
        visible: !Theme.pip && root.current
        height: 1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        color: Theme.accent
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
