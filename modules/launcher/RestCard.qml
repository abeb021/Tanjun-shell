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

        Rectangle {
            width: parent.width
            height: 108
            color: Theme.surface
            border.width: 1
            border.color: Media.active ? Theme.accent : Theme.surface
            radius: Theme.radius

            Item {
                anchors.fill: parent
                anchors.margins: 10

                Rectangle {
                    id: artBox
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 88
                    height: 88
                    color: Theme.bg
                    radius: Theme.radius
                    clip: true
                    Image {
                        visible: Media.artUrl.length > 0
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        source: Media.artUrl
                    }
                    BarText {
                        visible: Media.artUrl.length === 0
                        anchors.centerIn: parent
                        text: Media.active ? "" : ""
                        icon: true
                        px: 28
                        color: Theme.fgSub
                    }
                }

                Column {
                    anchors.left: artBox.right
                    anchors.right: transport.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 6
                    BarText {
                        text: Media.title.length ? Media.title : "nothing playing"
                        px: 14
                        width: parent.width
                    }
                    BarText {
                        visible: Media.artist.length > 0
                        text: Media.artist
                        sub: true
                        px: 12
                        width: parent.width
                    }
                }

                Row {
                    id: transport
                    visible: Media.active
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    BarButton {
                        implicitWidth: 36
                        onClicked: if (Media.player && Media.player.canGoPrevious)
                            Media.player.previous()
                        BarText {
                            text: ""
                            icon: true
                        }
                    }
                    BarButton {
                        implicitWidth: 36
                        onClicked: if (Media.player)
                            Media.player.togglePlaying()
                        BarText {
                            text: Media.player && Media.player.isPlaying ? "" : ""
                            icon: true
                        }
                    }
                    BarButton {
                        implicitWidth: 36
                        onClicked: if (Media.player && Media.player.canGoNext)
                            Media.player.next()
                        BarText {
                            text: ""
                            icon: true
                        }
                    }
                }
            }
        }

        BarText {
            text: "= calc   ; clips   ? web   / act   @ music"
            sub: true
            px: 11
        }
    }
}
