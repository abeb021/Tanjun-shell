import QtQuick
import "../widgets"
import "../../services"

Rectangle {
    id: root
    color: Theme.surface
    border.width: 1
    border.color: Theme.hairline
    radius: Theme.radius
    implicitWidth: 280
    implicitHeight: Math.min(col.implicitHeight + 16, 420)
    focus: true

    readonly property var picks: {
        const out = [];
        const sinks = Audio.sinks || [];
        for (let i = 0; i < sinks.length; i++)
            out.push({
                kind: "sink",
                node: sinks[i]
            });
        const src = Audio.sources || [];
        for (let i = 0; i < src.length; i++)
            out.push({
                kind: "source",
                node: src[i]
            });
        return out;
    }

    KeyCatcher {
        id: catcher
        anchors.fill: parent
        focus: true
        count: root.picks.length
        onCancel: ShellState.closeMenus()
        onPick: i => {
            const it = root.picks[i];
            if (!it)
                return;
            if (it.kind === "sink")
                Audio.setSink(it.node);
            else
                Audio.setSource(it.node);
        }

        Flickable {
        anchors.fill: parent
        anchors.margins: 10
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: true

        Column {
            id: col
            width: parent.width
            spacing: 8

            BarText {
                text: Audio.muted ? "muted" : `${Math.round(Audio.volume * 100)}%`
                px: 12
            }

            Repeater {
                model: Audio.sinks
                delegate: BarButton {
                    required property var modelData
                    required property int index
                    implicitWidth: col.width
                    implicitHeight: 24
                    active: Audio.isCurrent(modelData, Audio.sink) || catcher.currentIndex === index
                    onClicked: Audio.setSink(modelData)
                    BarText {
                        text: (Audio.isCurrent(modelData, Audio.sink) ? "●  " : "○  ") + Audio.deviceName(modelData)
                        px: 12
                        color: Audio.isCurrent(modelData, Audio.sink) ? Theme.accent : Theme.fg
                        width: col.width - 16
                        elide: Text.ElideRight
                    }
                }
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
                visible: Audio.sources.length > 0
                text: Audio.micMuted ? "mic muted" : `mic  ${Math.round(Audio.micVolume * 100)}%`
                px: 12
            }

            Repeater {
                model: Audio.sources
                delegate: BarButton {
                    required property var modelData
                    required property int index
                    implicitWidth: col.width
                    implicitHeight: 24
                    active: Audio.isCurrent(modelData, Audio.source) || catcher.currentIndex === (Audio.sinks.length + index)
                    onClicked: Audio.setSource(modelData)
                    BarText {
                        text: (Audio.isCurrent(modelData, Audio.source) ? "●  " : "○  ") + Audio.deviceName(modelData)
                        px: 12
                        color: Audio.isCurrent(modelData, Audio.source) ? Theme.accent : Theme.fg
                        width: col.width - 16
                        elide: Text.ElideRight
                    }
                }
            }

            VolumeBar {
                visible: Audio.sources.length > 0
                width: parent.width
                value: Audio.micVolume
                fill: Audio.micMuted ? Theme.critical : Theme.accent
                onMoved: v => Audio.setMicVolume(v)
            }

            BarButton {
                visible: Audio.sources.length > 0
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

    Connections {
        target: ShellState
        function onPopoutChanged() {
            if (ShellState.popout === "audio")
                catcher.forceActiveFocus();
        }
    }
}
