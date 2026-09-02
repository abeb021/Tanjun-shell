import QtQuick
import Quickshell
import "../bar"
import "../../services"

Rectangle {
    color: Theme.surface
    border.width: 1
    border.color: Theme.bg
    radius: Theme.radius
    implicitWidth: 300
    implicitHeight: 360

    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 8
        clip: true
        spacing: 6
        model: Notifs.list
        delegate: Rectangle {
            required property var modelData
            width: list.width
            implicitHeight: col.implicitHeight + 10
            color: Theme.bg
            radius: Theme.radius
            Column {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                spacing: 2
                BarText {
                    text: modelData.summary || modelData.appName
                    px: 12
                    width: parent.width
                }
                BarText {
                    text: modelData.body || ""
                    sub: true
                    px: 11
                    width: parent.width
                    wrapMode: Text.Wrap
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: modelData.dismiss()
            }
        }

        BarText {
            visible: list.count === 0
            anchors.centerIn: parent
            text: ShellState.dnd ? "не беспокоить" : "нет уведомлений"
            sub: true
        }
    }
}
