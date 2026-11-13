import QtQuick
import "../widgets"
import "../../services"

// One line in a popover list. Compact, transparent until hovered, with an
// optional control on the right.
Item {
    id: root

    property string label: ""
    property string sub: ""
    property string icon: ""
    property bool active: false
    property bool danger: false
    property bool dimmed: false
    property bool clickable: false
    default property alias control: controlRow.data

    signal clicked

    readonly property bool hasIcon: icon.length > 0

    width: parent ? parent.width : 0
    height: sub.length > 0 ? 34 : 26

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: root.active ? Theme.hot : (hover.containsMouse ? Theme.hotSoft : "transparent")
        Behavior on color {
            enabled: Motion.ready
            ColorAnimation {
                duration: Motion.fast
            }
        }
    }

    BarText {
        visible: root.hasIcon
        width: visible ? 18 : 0
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        icon: true
        px: 12
        color: root.dimmed ? Theme.fgSub : (root.danger ? Theme.critical : (root.active ? Theme.accent : Theme.fgSub))
    }

    Column {
        id: copy
        anchors.left: parent.left
        anchors.leftMargin: root.hasIcon ? 26 : 4
        anchors.right: controlSlot.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        BarText {
            width: parent.width
            text: root.label
            px: 12
            family: Config.defaultFontUi
            color: root.dimmed ? Theme.fgSub : (root.danger ? Theme.critical : (root.active ? Theme.accent : Theme.fg))
            elide: Text.ElideRight
        }
        BarText {
            visible: root.sub.length > 0
            width: parent.width
            text: root.sub
            px: 9
            family: Config.defaultFontUi
            font.letterSpacing: 1
            color: Theme.fgSub
            elide: Text.ElideRight
        }
    }

    Item {
        id: controlSlot
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        width: controlRow.width
        height: parent.height

        Row {
            id: controlRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
        }
    }

    MouseArea {
        id: hover
        z: -1
        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: root.clickable
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
