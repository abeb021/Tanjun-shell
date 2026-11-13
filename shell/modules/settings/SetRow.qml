import QtQuick
import "../widgets"
import "../../services"

// One line in a settings list: leading icon, label and sub-label, with a
// control slot on the right. Rows are transparent until hovered, so a list
// reads as type and whitespace rather than as a stack of cards.
Item {
    id: root

    property string label: ""
    property string sub: ""
    property string icon: ""
    property bool active: false
    property bool danger: false
    property bool clickable: false
    default property alias control: controlRow.data

    signal clicked

    readonly property bool hasIcon: icon.length > 0

    width: parent ? parent.width : 0
    height: sub.length > 0 ? 48 : 40

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
        width: visible ? 24 : 0
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        icon: true
        px: 15
        color: root.danger ? Theme.critical : (root.active ? Theme.accent : Theme.fgSub)
    }

    Column {
        id: copy
        anchors.left: parent.left
        anchors.leftMargin: root.hasIcon ? 34 : 4
        anchors.right: controlSlot.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        BarText {
            width: parent.width
            text: root.label
            px: 12
            family: Config.defaultFontUi
            color: root.danger ? Theme.critical : (root.active ? Theme.accent : Theme.fg)
            elide: Text.ElideRight
        }
        BarText {
            visible: root.sub.length > 0
            width: parent.width
            text: root.sub
            px: 9
            family: Config.defaultFontUi
            font.letterSpacing: 1
            color: root.danger ? Theme.wash(Theme.critical, 0.7) : Theme.fgSub
            elide: Text.ElideRight
        }
    }

    Item {
        id: controlSlot
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: controlRow.width
        height: parent.height

        Row {
            id: controlRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
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
