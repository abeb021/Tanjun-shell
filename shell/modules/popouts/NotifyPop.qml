import QtQuick
import "../widgets"
import "../../services"

Face {
    job: "pop"
    implicitWidth: 300
    implicitHeight: 360
    focus: true
    Keys.onEscapePressed: ShellState.closeMenus()

    Row {
        id: actions
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        spacing: 6
        BarButton {
            implicitWidth: 140
            onClicked: ShellState.dnd = !ShellState.dnd
            BarText {
                text: ShellState.dnd ? "dnd · on" : "dnd · off"
                px: 11
            }
        }
        BarButton {
            implicitWidth: 72
            onClicked: Notifs.clear()
            BarText {
                text: "clear"
                px: 11
            }
        }
    }

    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 8
        anchors.topMargin: 40
        clip: true
        spacing: 6
        model: Notifs.list
        delegate: Rectangle {
            required property var modelData
            width: list.width
            implicitHeight: col.implicitHeight + 10
            color: Theme.bg
            radius: Theme.radius
            MouseArea {
                anchors.fill: parent
                onClicked: modelData.dismiss()
            }
            Column {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                spacing: 4
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
                Row {
                    visible: actRep.count > 0
                    spacing: 4
                    Repeater {
                        id: actRep
                        model: modelData.actions
                        BarButton {
                            required property var modelData
                            implicitWidth: Math.max(52, actLabel.implicitWidth + 12)
                            onClicked: modelData.invoke()
                            BarText {
                                id: actLabel
                                text: modelData.text
                                px: 10
                            }
                        }
                    }
                }
            }
        }

        BarText {
            visible: list.count === 0
            anchors.centerIn: parent
            text: ShellState.dnd ? "do not disturb" : "no notifications"
            sub: true
        }
    }
}
