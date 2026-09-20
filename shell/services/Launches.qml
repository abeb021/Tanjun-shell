pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var hits: ({})
    property int gen: 0
    property bool writing: false

    readonly property string path: `${Config.stateDir}/launches.json`

    function count(id) {
        gen;
        if (!id)
            return 0;
        const h = hits[id];
        return h && h.n ? h.n : 0;
    }

    function last(id) {
        gen;
        if (!id)
            return 0;
        const h = hits[id];
        return h && h.t ? h.t : 0;
    }

    function bump(id) {
        if (!id || !`${id}`.length)
            return;
        const next = {};
        const keys = Object.keys(hits);
        for (let i = 0; i < keys.length; i++)
            next[keys[i]] = hits[keys[i]];
        const cur = next[id] || { n: 0, t: 0 };
        next[id] = { n: (cur.n || 0) + 1, t: Date.now() };
        const keys2 = Object.keys(next);
        if (keys2.length > 80) {
            keys2.sort((a, b) => (next[a].t || 0) - (next[b].t || 0));
            const drop = keys2.length - 80;
            for (let i = 0; i < drop; i++)
                delete next[keys2[i]];
        }
        hits = next;
        gen++;
        persist();
    }

    function persist() {
        Config.ensureStateDir();
        writing = true;
        file.setText(JSON.stringify(hits));
        Qt.callLater(() => {
            root.writing = false;
        });
    }

    FileView {
        id: file
        path: root.path
        printErrors: false
        atomicWrites: true
        watchChanges: true
        onFileChanged: {
            if (!root.writing)
                reload();
        }
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d && typeof d === "object")
                    root.hits = d;
            } catch (e) {}
            root.gen++;
        }
    }
}
