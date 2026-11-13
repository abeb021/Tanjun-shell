import QtQuick
import "../widgets"
import "../../services"

// Centred empty state for a list that has nothing to show yet.
Item {
    id: root

    property string icon: ""
    property string title: ""
    property string hint: ""

    width: parent ? parent.width : 0
    implicitHeight: 92
    height: implicitHeight

    Column {
        anchors.centerIn: parent
        spacing: 7

        BarText {
            visible: root.icon.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            icon: true
            px: 22
            color: Theme.fgSub
        }
        BarText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.title
            px: 10
            family: Config.defaultFontUi
            font.letterSpacing: 1
            color: Theme.fgSub
        }
        BarText {
            visible: root.hint.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.hint
            px: 9
            family: Config.defaultFontUi
            color: Theme.fgSub
        }
    }
}
