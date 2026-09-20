pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string wallPick: ""
    property string paintKind: "dark"
    property string paintName: "monochrome"

    readonly property string wallDir: `${Config.stateDir}/walls`
    readonly property string wallDirLegacy: `${Config.configHome}/hypr/assets/wallpapers`
    readonly property url wallFolder: Qt.url("file://" + wallDir)

    function urlPath(u) {
        let s = `${u}`;
        if (s.startsWith("file://")) {
            s = decodeURIComponent(s.slice(7));
            if (s.startsWith("localhost"))
                s = s.slice("localhost".length);
        }
        return s;
    }

    function setWallpaper(path) {
        const p = urlPath(path);
        if (!p.length)
            return;
        wallPick = p;
        setProc.running = false;
        Qt.callLater(() => {
            setProc.running = true;
        });
    }

    function paint(nextKind, nextName) {
        const n = Theme.slug(nextName || Theme.name, "");
        if (!n.length || n === "wall")
            return;
        paintKind = Theme.slug(nextKind || Theme.kind, "dark");
        paintName = n;
        paintProc.running = false;
        Qt.callLater(() => {
            paintProc.running = true;
        });
    }

    function sample() {
        sampleProc.running = false;
        Qt.callLater(() => {
            sampleProc.running = true;
        });
    }

    Process {
        id: setProc
        command: ["python3", `${Quickshell.shellDir}/scripts/tanjun-paint.py`, Config.theme.sampleWall ? "set" : "wall", root.wallPick]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    if (d.accent)
                        Theme.applyWallJson(d);
                    else {
                        Theme.applyWallMedia(d);
                        Theme.persist(Theme.kind, Theme.name);
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: paintProc
        command: ["python3", `${Quickshell.shellDir}/scripts/tanjun-paint.py`, root.paintKind, root.paintName]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    Theme.applyWallMedia(JSON.parse(text));
                    Theme.persist(Theme.kind, Theme.name);
                } catch (e) {}
            }
        }
    }

    Process {
        id: sampleProc
        command: ["python3", `${Quickshell.shellDir}/scripts/tanjun-paint.py`, "sample"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    Theme.applyWallJson(JSON.parse(text));
                } catch (e) {}
            }
        }
    }
}
