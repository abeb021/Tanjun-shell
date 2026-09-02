import QtQuick
import Quickshell
import "../bar"
import "../../services"

Item {
    id: root
    width: parent.width
    height: parent.height

    Column {
        anchors.fill: parent
        spacing: 14

        Row {
            spacing: 16
            width: parent.width

            Column {
                spacing: 4
                BarText {
                    text: Time.time
                    px: 52
                }
                BarText {
                    text: Time.tzLabel + "  ·  " + Time.date
                    sub: true
                    px: 13
                }
            }

            Rectangle {
                width: 220
                height: 88
                color: Theme.surface
                border.width: 1
                border.color: Theme.accent
                radius: Theme.radius
                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4
                    BarText {
                        text: Config.services.weatherCity.length ? Config.services.weatherCity : Config.localLabel
                        sub: true
                        px: 11
                    }
                    BarText {
                        text: Weather.text || "…"
                        px: 22
                        width: parent.width
                        wrapMode: Text.Wrap
                    }
                }
            }
        }

        PlayerCard {
            width: parent.width
            artSize: 88
        }

        BarText {
            text: "= calc   ; clips   ? web   / act   @ music"
            sub: true
            px: 11
        }
    }
}
