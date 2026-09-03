import QtQuick
import "../widgets"
import "../../services"

Rectangle {
    color: Theme.surface
    border.width: 1
    border.color: Theme.bg
    radius: Theme.radius
    implicitWidth: 260
    implicitHeight: Math.min(col.implicitHeight + 16, 420)
    focus: true
    Keys.onEscapePressed: ShellState.closeMenus()

    Flickable {
        anchors.fill: parent
        anchors.margins: 10
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 10

            BarText {
                text: Audio.muted ? "muted" : `${Math.round(Audio.volume * 100)}%`
                px: 12
            }

            VolumeBar {
                width: parent.width
                value: Audio.volume
                fill: Audio.muted ? Theme.critical : Theme.accent
                onMoved: v => Audio.setVolume(v)
            }

            BarButton {
                implicitWidth: 72
                onClicked: Audio.toggleMute()
                BarText {
                    text: Audio.muted ? "unmute" : "mute"
                    px: 11
                }
            }

            BarText {
                visible: Audio.source
                text: Audio.micMuted ? "mic muted" : `mic  ${Math.round(Audio.micVolume * 100)}%`
                px: 12
            }

            VolumeBar {
                visible: Audio.source
                width: parent.width
                value: Audio.micVolume
                fill: Audio.micMuted ? Theme.critical : Theme.accent
                onMoved: v => Audio.setMicVolume(v)
            }

            BarButton {
                visible: Audio.source
                implicitWidth: 72
                onClicked: Audio.toggleMicMute()
                BarText {
                    text: Audio.micMuted ? "unmute" : "mute"
                    px: 11
                }
            }

            Repeater {
                model: Audio.streams
                delegate: Column {
                    required property var modelData
                    width: col.width
                    spacing: 4
                    BarText {
                        text: Audio.streamName(modelData)
                        px: 11
                        width: parent.width
                        elide: Text.ElideRight
                    }
                    VolumeBar {
                        width: parent.width
                        value: modelData.audio ? modelData.audio.volume : 0
                        fill: Theme.accent
                        onMoved: v => Audio.setStreamVolume(modelData, v)
                    }
                }
            }
        }
    }
}
