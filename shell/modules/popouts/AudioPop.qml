import QtQuick
import Quickshell
import "../widgets"
import "../../services"

Face {
    id: root
    job: "pop"
    attach: true
    frosted: true
    implicitWidth: 300
    implicitHeight: Math.min(col.implicitHeight + 24, 440)
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
        onCancel: UiMode.closeMenus()
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
            anchors.margins: 12
            contentWidth: width
            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: true

            Column {
                id: col
                width: parent.width
                spacing: 10

                PopHead {
                    title: "VOLUME"
                    status: Audio.muted ? "MUTED" : `${Math.round(Audio.volume * 100)}%`
                    PopChip {
                        icon: Audio.muted ? "󰝟" : "󰕾"
                        danger: Audio.muted
                        onClicked: Audio.toggleMute()
                    }
                }

                VolumeBar {
                    width: parent.width
                    thumb: true
                    value: Audio.volume
                    fill: Audio.muted ? Theme.critical : Theme.accent
                    onMoved: v => Audio.setVolume(v)
                }

                Repeater {
                    model: Audio.sinks
                    PopRow {
                        required property var modelData
                        required property int index
                        active: Audio.isCurrent(modelData, Audio.sink) || catcher.currentIndex === index
                        clickable: true
                        icon: Audio.deviceIcon(modelData)
                        label: Audio.deviceName(modelData)
                        onClicked: Audio.setSink(modelData)
                    }
                }

                PopHead {
                    visible: Audio.sources.length > 0
                    title: "MIC"
                    PopChip {
                        icon: Audio.micMuted ? "󰍭" : "󰍬"
                        danger: Audio.micMuted
                        onClicked: Audio.toggleMicMute()
                    }
                }

                Repeater {
                    model: Audio.sources
                    PopRow {
                        required property var modelData
                        required property int index
                        active: Audio.isCurrent(modelData, Audio.source) || catcher.currentIndex === (Audio.sinks.length + index)
                        clickable: true
                        icon: Audio.deviceIcon(modelData)
                        label: Audio.deviceName(modelData)
                        onClicked: Audio.setSource(modelData)
                    }
                }

                VolumeBar {
                    visible: Audio.sources.length > 0
                    width: parent.width
                    thumb: true
                    value: Audio.micVolume
                    fill: Audio.micMuted ? Theme.critical : Theme.accent
                    onMoved: v => Audio.setMicVolume(v)
                }

                PopHead {
                    visible: Audio.streams.length > 0
                    title: "APPS"
                    status: `${Audio.streams.length}`
                }

                Repeater {
                    model: Audio.streams
                    Column {
                        required property var modelData
                        width: col.width
                        spacing: 3

                        PopRow {
                            icon: "󰎆"
                            danger: !!(modelData.audio && modelData.audio.muted)
                            clickable: true
                            label: Audio.streamName(modelData)
                            onClicked: Audio.toggleStreamMute(modelData)
                        }

                        VolumeBar {
                            width: parent.width
                            value: modelData.audio ? modelData.audio.volume : 0
                            fill: (modelData.audio && modelData.audio.muted) ? Theme.critical : Theme.accent
                            onMoved: v => Audio.setStreamVolume(modelData, v)
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: UiMode
        function onPopoutChanged() {
            if (UiMode.popout === "audio")
                catcher.forceActiveFocus();
        }
    }
}
