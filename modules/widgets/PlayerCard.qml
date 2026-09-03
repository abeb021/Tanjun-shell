import QtQuick
import "../../services"

Item {
    id: root
    property int artSize: 64
    property bool live: true
    implicitHeight: artSize + 20
    implicitWidth: parent ? parent.width : 280

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        border.width: 1
        border.color: Media.active ? Theme.accent : Theme.surface
        radius: Theme.radius
    }

    Item {
        anchors.fill: parent
        anchors.margins: 8

        Rectangle {
            id: artBox
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: root.artSize
            height: root.artSize
            color: Theme.bg
            radius: Theme.radius
            clip: true
            Image {
                visible: root.live && Media.artUrl.length > 0
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                sourceSize: Qt.size(root.artSize, root.artSize)
                source: root.live && Media.artUrl.length > 0 ? Media.artUrl : ""
            }
            BarText {
                visible: Media.artUrl.length === 0
                anchors.centerIn: parent
                text: Media.active ? "" : ""
                icon: true
                px: Math.round(root.artSize * 0.32)
                color: Theme.fgSub
            }
        }

        Column {
            anchors.left: artBox.right
            anchors.right: transport.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            anchors.rightMargin: 6
            spacing: 4
            BarText {
                text: Media.title.length ? Media.title : "nothing playing"
                px: 12
                width: parent.width
            }
            BarText {
                visible: Media.artist.length > 0
                text: Media.artist
                sub: true
                px: 11
                width: parent.width
            }
        }

        Row {
            id: transport
            visible: Media.active
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            BarButton {
                implicitWidth: 32
                onClicked: if (Media.player && Media.player.canGoPrevious)
                    Media.player.previous()
                BarText {
                    text: ""
                    icon: true
                    px: 12
                }
            }
            BarButton {
                implicitWidth: 32
                onClicked: if (Media.player)
                    Media.player.togglePlaying()
                BarText {
                    text: Media.player && Media.player.isPlaying ? "" : ""
                    icon: true
                    px: 12
                }
            }
            BarButton {
                implicitWidth: 32
                onClicked: if (Media.player && Media.player.canGoNext)
                    Media.player.next()
                BarText {
                    text: ""
                    icon: true
                    px: 12
                }
            }
        }
    }
}
