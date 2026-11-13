import QtQuick
import "../widgets"
import "../../services"

// Compact masthead for a bar popover: what this menu is, and its state.
Item {
    id: root

    property string title: ""
    property string status: ""
    default property alias extra: extraRow.data

    width: parent ? parent.width : 0
    implicitHeight: 22
    height: implicitHeight

    BarText {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        role: "head"
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
