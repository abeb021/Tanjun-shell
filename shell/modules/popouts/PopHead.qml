import QtQuick
import "../widgets"
import "../../services"

// Compact masthead for a bar popover: what this menu is, and its state. An icon
// usually says what the title would, which keeps the header to one short line.
Item {
    id: root

    property string icon: ""
    property string title: ""
    property string status: ""
    default property alias extra: extraRow.data

    width: parent ? parent.width : 0
    implicitHeight: 22
    height: implicitHeight

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        BarText {
            visible: root.icon.length > 0
            text: root.icon
            icon: true
            px: 13
            color: Theme.caption
        }

        BarText {
            visible: root.title.length > 0
            text: root.title
            role: "head"
        }
    }

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        BarText {
            visible: root.status.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.status
            px: 9
            family: Config.defaultFontUi
            font.letterSpacing: 1
            color: Theme.fgSub
        }

        Row {
            id: extraRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
        }
    }
}
