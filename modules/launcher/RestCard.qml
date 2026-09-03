import QtQuick
import "../widgets"
import "../../services"

Item {
    id: root
    width: parent.width
    height: parent.height

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
                BarText {
                    text: Config.services.weatherCity.length ? Config.services.weatherCity : Config.localLabel
                    role: "caption"
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
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
            live: ShellState.launcherOpen
        }

        Row {
            spacing: 16
            Repeater {
                model: [
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
