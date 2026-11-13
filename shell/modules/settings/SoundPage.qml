import QtQuick
import "../widgets"
import "../../services"

Column {
    width: parent.width
    spacing: 16

    SetHead {
        title: "OUTPUT"
        desc: "Click the row to mute."
    }

    SetRow {
        icon: Audio.muted ? "" : ""
        label: "VOLUME"
        sub: Audio.muted ? "MUTED" : `${Math.round(Audio.volume * 100)}%`
        clickable: true
        danger: Audio.muted
        onClicked: Audio.toggleMute()
        HudSlider {
            width: Math.min(260, Math.max(160, page.width * 0.4))
            value: Audio.muted ? 0 : Audio.volume
            accentColor: Audio.muted ? Theme.critical : Theme.accent
            onMoved: v => Audio.setVolume(v)
        }
    }

    Repeater {
        model: Audio.sinks
        SetRow {
            required property var modelData
            active: Audio.isCurrent(modelData, Audio.sink)
            clickable: true
            icon: Audio.isCurrent(modelData, Audio.sink) ? "" : ""
            label: Audio.deviceName(modelData).toUpperCase()
            onClicked: Audio.setSink(modelData)
        }
    }

    SetEmpty {
        visible: Audio.sinks.length === 0
        icon: ""
        title: "NO AUDIO OUTPUTS"
        hint: "Connect a device."
    }

    SetHead {
        title: "APPS"
        desc: Audio.streams.length > 0 ? `${Audio.streams.length} playing · click to mute` : "Nothing is playing."
    }

    Repeater {
        model: Audio.streams
        SetRow {
            required property var modelData
            danger: !!(modelData.audio && modelData.audio.muted)
            clickable: true
            icon: (modelData.audio && modelData.audio.muted) ? "" : ""
            label: Audio.streamName(modelData).toUpperCase()
            onClicked: Audio.toggleStreamMute(modelData)
            HudSlider {
                width: Math.min(220, Math.max(140, page.width * 0.34))
                value: (modelData.audio && modelData.audio.muted) ? 0 : (modelData.audio ? modelData.audio.volume : 0)
                accentColor: (modelData.audio && modelData.audio.muted) ? Theme.critical : Theme.accent
                onMoved: v => Audio.setStreamVolume(modelData, v)
            }
        }
    }

    SetHead {
        title: "MIC"
        desc: Audio.sources.length > 0 ? "Input volume and mute." : "No microphone."
    }

    Repeater {
        model: Audio.sources
        SetRow {
            required property var modelData
            active: Audio.isCurrent(modelData, Audio.source)
            clickable: true
            icon: Audio.isCurrent(modelData, Audio.source) ? "" : ""
            label: Audio.deviceName(modelData).toUpperCase()
            onClicked: Audio.setSource(modelData)
        }
    }

    SetRow {
        visible: Audio.sources.length > 0
        icon: ""
        label: "MIC VOLUME"
        sub: Audio.micLabel
        clickable: true
        danger: Audio.micMuted
        onClicked: Audio.toggleMicMute()
        HudSlider {
            width: Math.min(260, Math.max(160, page.width * 0.4))
            value: Audio.micMuted ? 0 : Audio.micVolume
            accentColor: Audio.micMuted ? Theme.critical : Theme.accent
            onMoved: v => Audio.setMicVolume(v)
        }
    }
}
