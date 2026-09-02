pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: {
        const a = sink?.audio;
        if (!a)
            return 0;
        return a.muted ? 0 : a.volume;
    }
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string label: muted ? "muted" : `${Math.round(volume * 100)}%`

    property real lastVolume: -1

    onVolumeChanged: {
        if (lastVolume < 0) {
            lastVolume = volume;
            return;
        }
        if (Math.abs(volume - lastVolume) < 0.004)
            return;
        lastVolume = volume;
        ShellState.showOsd("volume", muted ? 0 : volume);
    }

    function setVolume(v) {
        if (!sink?.audio)
            return;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function nudge(delta) {
        setVolume(volume + delta);
    }

    function toggleMute() {
        if (!sink?.audio)
            return;
        sink.audio.muted = !sink.audio.muted;
    }
}
