import QtQuick
import "../bar"
import "../../services"

Rectangle {
    id: root
    property string title: ""
    default property alias content: inner.data

    width: parent ? parent.width : 280
    implicitHeight: box.implicitHeight + 16
    color: Theme.surface
    border.width: 1
    border.color: Theme.surfaceHover
    radius: Theme.radius

    Column {
        id: box
        x: 8
        y: 8
        width: parent.width - 16
        spacing: 8

        BarText {
            visible: root.title.length > 0
            text: root.title
            sub: true
            px: 10
        }

        Column {
            id: inner
            width: parent.width
            spacing: 8
        }
    }
}
