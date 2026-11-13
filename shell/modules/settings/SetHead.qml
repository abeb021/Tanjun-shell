import QtQuick
import "../widgets"
import "../../services"

// Section masthead for a settings page: a small uppercase title, an optional
// one-line explanation, and an optional control parked on the right.
Item {
    id: root

    property string title: ""
    property string desc: ""
    default property alias extra: slot.data

    width: parent ? parent.width : 0
    implicitHeight: Math.max(28, copy.implicitHeight)
    height: implicitHeight

    Column {
        id: copy
        anchors.left: parent.left
        anchors.right: slot.left
        anchors.rightMargin: 16
        anchors.top: parent.top
        spacing: 3

        BarText {
            text: root.title
            role: "head"
        }
        BarText {
            visible: root.desc.length > 0
            width: parent.width
            text: root.desc
            px: 11
            family: Config.defaultFontUi
            color: Theme.fgSub
            wrapMode: Text.Wrap
        }
    }

    Row {
        id: slot
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14
    }
}
