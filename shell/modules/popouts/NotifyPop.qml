import QtQuick
import "../widgets"
import "../../services"

Face {
    id: root
    job: "pop"
    attach: true
    frosted: true
    implicitWidth: 320
    implicitHeight: 380
    focus: true
    Keys.onEscapePressed: UiMode.closeMenus()

    PopHead {
        id: head
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        title: "NOTIFICATIONS"
        status: `${Notifs.count}`

        PopChip {
            label: "DND"
            active: UiMode.dnd
            onClicked: UiMode.toggleDnd()
        }
        PopChip {
            label: "CLEAR"
            onClicked: Notifs.clear()
        }
    }

    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 12
        anchors.topMargin: 46
        clip: true
        spacing: 6
        model: Notifs.list
        add: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Motion.fast
                easing.type: Motion.enterEase
            }
            NumberAnimation {
                property: "y"
                from: Motion.popY
                duration: Motion.fast
                easing.type: Motion.enterEase
            }
        }
        displaced: Transition {
            NumberAnimation {
                properties: "y"
                duration: Motion.fast
                easing.type: Motion.easeOut
            }
        }
        delegate: Rectangle {
            required property var modelData
            width: list.width
            implicitHeight: card.implicitHeight + 18
            radius: Theme.radius
            color: Theme.surface

            Column {
                id: card
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 9
                spacing: 4

                BarText {
                    text: modelData.summary || modelData.appName
                    px: 12
                    family: Config.defaultFontUi
                    width: parent.width
                    elide: Text.ElideRight
                }
                BarText {
                    visible: `${modelData.body || ""}`.length > 0
                    text: modelData.body || ""
                    px: 11
                    family: Config.defaultFontUi
                    color: Theme.fgSub
                    width: parent.width
                    wrapMode: Text.Wrap
                }
                Row {
                    visible: actRep.count > 0
                    spacing: 12
                    Repeater {
                        id: actRep
                        model: modelData.actions
                        BarText {
                            required property var modelData
                            text: modelData.text
                            px: 9
                            family: Config.defaultFontUi
                            font.letterSpacing: 1
                            color: Theme.accent
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.invoke()
                            }
                        }
                    }
                }
            }

            MouseArea {
                z: -1
                anchors.fill: parent
                onClicked: modelData.dismiss()
            }
        }

        Item {
            visible: list.count === 0
            width: list.width
            height: list.height
            Column {
                anchors.centerIn: parent
                spacing: 6
                BarText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: ""
                    icon: true
                    px: 22
                    color: Theme.fgSub
                }
                BarText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: UiMode.dnd ? "DND" : "EMPTY"
                    px: 10
                    family: Config.defaultFontUi
                    font.letterSpacing: 1
                    color: Theme.fgSub
                }
            }
        }
    }
}
