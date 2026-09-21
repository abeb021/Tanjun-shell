import QtQuick
import "../widgets"
import "../../services"

Rectangle {
    id: root

    property string kind: ""
    property string label: ""
    property string blurb: ""
    readonly property bool panel: kind === "chrome" || kind === "panel"
    readonly property bool current: Theme.style === kind

    width: parent.width
    implicitHeight: 132
    height: implicitHeight
    radius: Theme.radius
    color: current ? Theme.wash(Theme.accent, panel ? 0.10 : 0.06) : (hover.containsMouse ? Theme.surfaceHover : "transparent")
    border.width: 1
    border.color: current || hover.containsMouse ? Theme.accent : Theme.hairline

    signal clicked

    Item {
        id: preview
        width: 168
        height: 88
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        clip: true

        Rectangle {
            anchors.fill: parent
            color: Theme.bg
            border.width: 1
            border.color: root.panel ? Theme.accent : Theme.hairline
            radius: Theme.radius
        }

        Repeater {
            model: root.panel ? 4 : 0
            Rectangle {
                required property int index
                width: index % 2 === 0 ? 18 : 2
                height: index % 2 === 0 ? 2 : 18
                color: Theme.accent
                x: index < 2 ? 8 : preview.width - (index % 2 === 0 ? 26 : 10)
                y: index < 2 ? 8 : preview.height - (index % 2 === 0 ? 10 : 26)
            }
        }

        Rectangle {
            width: 3
            height: 22
            visible: root.panel
            color: Theme.accent
            x: 14
            y: 28
        }

        Rectangle {
            width: 44
            height: root.panel ? 22 : 18
            x: 22
            y: 28
            radius: Theme.radius
            color: root.panel ? Theme.wash(Theme.accent, 0.10) : Theme.surfaceHover
            border.width: root.panel ? 1 : 0
            border.color: Theme.accent
            Rectangle {
                visible: !root.panel
                width: parent.width - 8
                height: 1
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                color: Theme.accent
            }
        }

        Rectangle {
            width: 52
            height: 6
            radius: 2
            x: 22
            y: 58
            color: Theme.surface
            border.width: 1
            border.color: Theme.hairline
            Rectangle {
                width: parent.width * 0.55
                height: parent.height
                radius: 2
                color: Theme.accent
            }
            Rectangle {
                visible: root.panel
                anchors.fill: parent
                anchors.margins: -2
                radius: 4
                color: "transparent"
                border.width: 2
                border.color: Theme.wash(Theme.accent, 0.35)
            }
        }
    }

    Column {
        anchors.left: preview.right
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16
        anchors.rightMargin: 14
        spacing: 6

        BarText {
            text: root.label
            px: 14
            family: Config.defaultFontUi
            color: root.current ? Theme.accent : Theme.fg
        }
        BarText {
            text: root.blurb
            px: 11
            family: Config.defaultFontUi
            color: Theme.fgSub
            width: parent.width
            wrapMode: Text.Wrap
        }
        BarText {
            visible: root.current
            text: "SELECTED"
            role: "head"
        }
    }

    MouseArea {
        id: hover
        z: 2
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
