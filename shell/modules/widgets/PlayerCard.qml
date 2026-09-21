import QtQuick
import "../../services"

Item {
    id: root
    property int artSize: 64
    property bool live: true
    implicitHeight: artSize
    implicitWidth: parent ? parent.width : 280

    Rectangle {
        id: artBox
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: root.artSize
        height: root.artSize
        color: Theme.surface
        radius: Theme.radius
        clip: true
        Image {
            visible: root.live && Media.artUrl.length > 0
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
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
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        spacing: 2
        BarText {
            text: Media.title.length ? Media.title : "nothing playing"
            width: parent.width
            elide: Text.ElideRight
        }
        BarText {
            visible: Media.artist.length > 0
            text: Media.artist
            role: "caption"
            width: parent.width
            elide: Text.ElideRight
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
                color: Theme.accent
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
