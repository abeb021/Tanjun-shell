pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int percent: -1
    property string discovered: ""
    property int want: -1
    property int sending: -1
    property int lastOsd: -1
    readonly property int pollMs: 0

    readonly property string blDev: Config.services.backlight.length ? Config.services.backlight : discovered
    readonly property string blRoot: blDev.length ? `/sys/class/backlight/${blDev}` : ""
    readonly property bool pushing: want >= 0 || setProc.running

    onPercentChanged: {
        if (percent < 0)
            return;
        if (lastOsd < 0) {
            lastOsd = percent;
            return;
        }
        if (Math.abs(percent - lastOsd) < 1)
            return;
        lastOsd = percent;
        OsdBus.show("brightness", percent / 100);
    }

    function clamp(p) {
        return Math.max(1, Math.min(100, Math.round(Number(p))));
    }

    function ctl(extra) {
        const out = ["brightnessctl"];
        if (blDev.length) {
            out.push("-d");
            out.push(blDev);
        }
        for (let i = 0; i < extra.length; i++)
            out.push(extra[i]);
        return out;
    }

    function applySysfs() {
        if (pushing)
            return;
        const a = parseInt(brNow.text().trim());
        const b = parseInt(brMax.text().trim());
        if (isNaN(a) || isNaN(b) || b <= 0)
            return;
        const n = Math.max(0, Math.min(100, Math.round(100 * a / b)));
        if (n === root.percent)
            return;
        root.percent = n;
    }

    function applyCli(raw) {
        if (pushing)
            return;
        const n = parseInt(raw.trim());
        if (isNaN(n) || n === root.percent)
            return;
        root.percent = n;
    }

    function refresh() {
        if (pushing)
            return;
        if (blRoot.length) {
            brNow.reload();
            brMax.reload();
            return;
        }
        cliProc.running = true;
    }

    function setPercent(p) {
        const n = clamp(p);
        percent = n;
        want = n;
        if (!setProc.running)
            flush();
    }

    function nudge(delta) {
        setPercent((percent < 0 ? 50 : percent) + delta);
    }

    function flush() {
        if (want < 0)
            return;
        sending = want;
        want = -1;
        setProc.command = ctl(["set", `${sending}%`]);
        setProc.running = true;
    }

    Process {
        id: findBl
        running: Config.services.backlight.length === 0
        command: ["sh", "-c", "for d in /sys/class/backlight/*; do [ -r \"$d/brightness\" ] && basename \"$d\" && break; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (t.length && t !== "*")
                    root.discovered = t;
            }
        }
    }

    FileView {
        id: brNow
        path: root.blRoot.length ? `${root.blRoot}/brightness` : ""
        printErrors: false
        watchChanges: true
        onLoaded: root.applySysfs()
        onFileChanged: reload()
    }

    FileView {
        id: brMax
        path: root.blRoot.length ? `${root.blRoot}/max_brightness` : ""
        printErrors: false
        watchChanges: true
        onLoaded: root.applySysfs()
    }

    Process {
        id: setProc
        running: false
        onExited: {
            if (root.want >= 0)
                root.flush();
            else
                Qt.callLater(root.refresh);
        }
    }

    Process {
        id: cliProc
        command: ctl(["-m"])
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",");
                if (parts.length >= 4)
                    root.applyCli(parts[3].replace("%", ""));
            }
        }
    }

    onBlRootChanged: if (blRoot.length)
        Qt.callLater(refresh)

    Component.onCompleted: Qt.callLater(refresh)

    Timer {
        interval: 2000
        running: root.blRoot.length === 0 && !root.pushing
        repeat: true
        onTriggered: root.refresh()
    }
}
