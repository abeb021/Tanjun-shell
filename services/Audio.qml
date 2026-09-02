pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    PwObjectTracker {
        objects: root.tracked
    }

    readonly property var tracked: {
        const out = [];
        if (Pipewire.defaultAudioSink)
            out.push(Pipewire.defaultAudioSink);
        const nodes = Pipewire.nodes.values;
        if (nodes) {
            for (let i = 0; i < nodes.length; i++) {
                const n = nodes[i];
                if (n && n.isStream)
                    out.push(n);
            }
        }
        return out;
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

    readonly property var streams: {
        const nodes = Pipewire.nodes.values;
        const out = [];
        if (!nodes)
            return out;
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i];
            if (n && n.isStream && n.isSink && n.audio)
                out.push(n);
        }
        return out;
    }

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

    function setStreamVolume(node, v) {
        if (!node?.audio)
            return;
        node.audio.volume = Math.max(0, Math.min(1, v));
    }

    function streamName(node) {
        if (!node)
            return "app";
        return node.nickname || node.description || node.name || "app";
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
