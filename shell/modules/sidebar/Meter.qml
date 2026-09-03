import QtQuick
import "../widgets"
import "../../services"

Column {
    id: root
    property string icon: ""
    property string label: ""
    property string value: ""
    property real ratio: 0
    property color fill: Theme.accent
    property bool interactive: true
    property bool danger: false
    property bool iconClickable: false
    property int valueWidth: 44
    signal iconClicked
    signal moved(real v)

    width: parent ? parent.width : 280
    spacing: 4

    Row {
        width: parent.width
        spacing: 6
        Item {
            width: 16
            height: 16
            BarText {
                anchors.centerIn: parent
                text: root.icon
                icon: true
                px: 13
                color: root.danger ? Theme.critical : Theme.fg
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.iconClickable
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconClicked()
            }
        }
        BarText {
            text: root.label.length ? root.label : root.value
            px: 12
            width: parent.width - 22 - (root.label.length ? root.valueWidth + 6 : 0)
            elide: Text.ElideRight
            color: root.danger ? Theme.critical : Theme.fg
        }
        BarText {
            visible: root.label.length > 0
            width: root.valueWidth
            text: root.value
            sub: true
            px: 11
            horizontalAlignment: Text.AlignRight
        }
    }
    VolumeBar {
        width: parent.width
        value: root.ratio
        fill: root.fill
        interactive: root.interactive
        onMoved: v => root.moved(v)
    }
}
