import QtQuick
import "../widgets"
import "../../services"

Rectangle {
    id: root

    required property var modelData
    property bool current: false

    width: parent.width
    height: 34
    radius: Theme.radius
    color: current ? Theme.hot : (hover.containsMouse ? Theme.hotSoft : "transparent")
    Behavior on color {
        enabled: Motion.ready
        ColorAnimation {
            duration: Motion.fast
        }
    }

    signal clicked

    Rectangle {
        visible: Theme.railMark && root.current
        width: 2
        height: parent.height - 8
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        color: Theme.accent
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 14
        spacing: 10

        BarText {
            text: modelData.icon
            icon: true
            px: 14
            color: root.current ? Theme.accent : Theme.fgSub
        }
        BarText {
            text: modelData.label
            px: 12
            family: Config.defaultFontUi
            color: root.current ? Theme.fg : Theme.fgSub
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
