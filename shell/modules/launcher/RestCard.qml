import QtQuick
import "../widgets"
import "../../services"

Item {
    id: root
    width: parent.width
    height: parent.height

    // The city is edited here, in the launcher, next to the forecast.
    property bool editing: false
    property string draft: ""

    function startEdit() {
        root.draft = Config.services.weatherCity;
        root.editing = true;
        Qt.callLater(() => {
            cityEdit.text = root.draft;
            cityEdit.forceActiveFocus();
        });
    }

    function commitCity() {
        if (!root.editing)
            return;
        const v = `${cityEdit.text}`.trim();
        if (v !== Config.services.weatherCity) {
            Config.services.weatherCity = v;
            Config.writeSparse();
        }
        root.editing = false;
    }

    Column {
        anchors.fill: parent
        spacing: Theme.pad

        Item {
            width: parent.width
            height: Math.max(clockCol.implicitHeight, weatherCol.implicitHeight)

            Column {
                id: clockCol
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                BarText {
                    text: Time.time
                    role: "display"
                }
                BarText {
                    text: Time.tzLabel + "  ·  " + Time.date
                    role: "caption"
                }
            }

            Column {
                id: weatherCol
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(220, parent.width * 0.42)
                spacing: 2
                Item {
                    width: parent.width
                    height: 22

                    Row {
                        visible: !root.editing
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        BarText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Config.services.weatherCity.length ? Config.services.weatherCity : Config.localLabel
                            role: "caption"
                        }

                        BarText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰏫"
                            icon: true
                            px: 10
                            color: penHover.hovered ? Theme.accent : Theme.fgSub
                            MouseArea {
                                id: penHover
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.startEdit()
                            }
                        }
                    }

                    Rectangle {
                        visible: root.editing
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(170, parent.width)
                        height: 22
                        radius: Theme.radius
                        color: Theme.surface
                        border.width: 1
                        border.color: cityEdit.activeFocus ? Theme.accent : Theme.hairline

                        TextInput {
                            id: cityEdit
                            anchors.fill: parent
                            anchors.margins: 5
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                            font.family: Theme.fontUi
                            font.pixelSize: Theme.typeCaption
                            color: Theme.fg
                            clip: true
                            selectByMouse: true
                            onTextEdited: root.draft = text
                            onEditingFinished: root.commitCity()
                            onActiveFocusChanged: if (!activeFocus && root.editing)
                                root.commitCity()
                            Keys.onReturnPressed: root.commitCity()
                            Keys.onEnterPressed: root.commitCity()
                            Keys.onEscapePressed: root.editing = false
                        }
                    }
                }
                BarText {
                    text: Weather.text.length ? Weather.text : "…"
                    role: "title"
                    width: parent.width
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        PlayerCard {
            width: parent.width
            artSize: 72
            live: UiMode.launcherOpen
        }

        Row {
            spacing: 16
            Repeater {
                model: [
                    { mark: "↓", label: "apps" },
                    { mark: "=", label: "calc" },
                    { mark: ";", label: "clips" },
                    { mark: "?", label: "web" },
                    { mark: "/", label: "act" },
                    { mark: "@", label: "music" }
                ]
                Row {
                    required property var modelData
                    spacing: 6
                    BarText {
                        text: modelData.mark
                        role: "caption"
                    }
                    BarText {
                        text: modelData.label
                        role: "caption"
                    }
                }
            }
        }
    }
}
