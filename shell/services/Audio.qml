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
        const nodes = Pipewire.nodes.values;
        if (!nodes)
            return out;
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i];
            if (!n)
                continue;
            if (n.isStream || n.audio)
                out.push(n);
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

    readonly property var source: Pipewire.defaultAudioSource
    readonly property real micVolume: {
        const a = source?.audio;
        if (!a)
            return 0;
        return a.muted ? 0 : a.volume;
    }
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property string micLabel: micMuted ? "muted" : `${Math.round(micVolume * 100)}%`

    readonly property var sinks: {
        const nodes = Pipewire.nodes.values;
        const out = [];
        if (!nodes)
            return out;
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i];
            if (n && !n.isStream && n.isSink && n.audio && !hideSink(n))
                out.push(n);
        }
        return out;
    }

    readonly property var sources: {
        const nodes = Pipewire.nodes.values;
        const out = [];
        if (!nodes)
            return out;
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i];
            if (n && !n.isStream && !n.isSink && n.audio && !hideSource(n))
                out.push(n);
        }
        return out;
    }

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

    function deviceName(node) {
        if (!node)
            return "device";
        return node.nickname || node.description || node.name || "device";
    }

    function attached(node) {
        if (!node || !node.ready)
            return false;
        const p = node.properties || {};
        const avail = `${p["port.available"] || p["port.availability"] || ""}`.toLowerCase();
        if (avail === "no" || avail === "n/a" || avail === "unavailable" || avail === "unplugged")
            return false;
        if (avail === "yes" || avail === "available")
            return true;
        return null;
    }

    function hideSink(node) {
        if (!node)
            return true;
        const a = attached(node);
        if (a === false)
            return true;
        if (a === true)
            return false;
        const nick = `${node.nickname || ""}`.toLowerCase();
        const desc = `${node.description || ""}`.toLowerCase();
        const name = `${node.name || ""}`.toLowerCase();
        const t = `${nick} ${desc} ${name}`;
        if (t.indexOf("headphone") >= 0)
            return true;
        if (/^hdmi\s*\d+$/.test(nick) || /^dp\s*\d+$/.test(nick))
            return true;
        if (!nick.length && /hdmi\d+/.test(name))
            return true;
        return false;
    }

    function hideSource(node) {
        if (!node)
            return true;
        const a = attached(node);
        if (a === false)
            return true;
        if (a === true)
            return false;
        const t = `${node.nickname || ""} ${node.description || ""} ${node.name || ""}`.toLowerCase();
        return t.indexOf("stereo microphone") >= 0;
    }

    function isCurrent(node, cur) {
        if (!node || !cur)
            return false;
        if (node === cur)
            return true;
        return node.id !== undefined && node.id === cur.id;
    }

    function setDefaultNode(node) {
        if (!node)
            return;
        const id = node.id;
        if (id === undefined || id === null)
            return;
        Quickshell.execDetached(["wpctl", "set-default", `${id}`]);
    }

    function setSink(node) {
        if (!node)
            return;
        Pipewire.preferredDefaultAudioSink = node;
        setDefaultNode(node);
    }

    function setSource(node) {
        if (!node)
            return;
        Pipewire.preferredDefaultAudioSource = node;
        setDefaultNode(node);
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

    function setMicVolume(v) {
        if (!source?.audio)
            return;
        source.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleMicMute() {
        if (!source?.audio)
            return;
        source.audio.muted = !source.audio.muted;
    }
}
