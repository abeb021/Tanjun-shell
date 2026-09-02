pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var player: {
        const list = Mpris.players.values;
        if (!list || list.length === 0)
            return null;
        for (let i = 0; i < list.length; i++) {
            if (list[i].isPlaying)
                return list[i];
        }
        return list[0];
    }

    readonly property bool active: player !== null
    readonly property string title: player ? (player.trackTitle || "") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string line: {
        if (!player)
            return "";
        const a = artist;
        const t = title;
        if (a && t)
            return `${a} — ${t}`;
        return t || a || player.identity;
    }
}
