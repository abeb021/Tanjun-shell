pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int percent: -1

    function refresh() {
        proc.running = true;
    }

    function nudge(delta) {
        const sign = delta > 0 ? "+" : "-";
        Quickshell.execDetached(["brightnessctl", "-e", "-d", "intel_backlight", "set", `${Math.abs(delta)}%${sign}`]);
        Qt.callLater(refresh);
    }

    function setPercent(p) {
        const n = Math.max(1, Math.min(100, Math.round(p)));
        Quickshell.execDetached(["brightnessctl", "-d", "intel_backlight", "set", `${n}%`]);
        Qt.callLater(refresh);
    }

    Process {
        id: proc
        command: ["bash", "-c", "brightnessctl -m -d intel_backlight | awk -F, '{gsub(/%/,\"\",$4); print $4}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim());
                if (isNaN(n))
                    return;
                const prev = root.percent;
                root.percent = n;
                if (prev >= 0 && prev !== n)
                    ShellState.showOsd("brightness", n / 100);
            }
        }
    }

    Timer {
        interval: 400
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
