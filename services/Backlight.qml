pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int percent: 50

    function refresh() {
        proc.running = true;
    }

    function nudge(delta) {
        const sign = delta > 0 ? "+" : "-";
        Quickshell.execDetached(["brightnessctl", "-e", "-d", "intel_backlight", "set", `${Math.abs(delta)}%${sign}`]);
        Qt.callLater(refresh);
    }

    Process {
        id: proc
        command: ["bash", "-c", "brightnessctl -m -d intel_backlight | awk -F, '{gsub(/%/,\"\",$4); print $4}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim());
                if (!isNaN(n)) {
                    if (root.percent !== n)
                        ShellState.showOsd("brightness", n / 100);
                    root.percent = n;
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
