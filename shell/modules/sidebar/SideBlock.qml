import QtQuick
import "../widgets"
import "../../services"

Face {
    id: root
    job: "pop"
    property string title: ""
    default property alias content: inner.data

    width: parent ? parent.width : 280
    implicitHeight: box.implicitHeight + 16

    Column {
        id: box
        x: 8
        y: 8
        width: parent.width - 16
        spacing: 8

        BarText {
            visible: root.title.length > 0
            text: root.title
            role: "head"
        }

        Column {
            id: inner
            width: parent.width
            spacing: 8
        }
    }
}
