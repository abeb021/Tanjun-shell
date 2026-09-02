pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string text: ""
    property string city: "Moscow"

    function refresh() {
        proc.running = true;
    }

    Process {
        id: proc
        command: ["curl", "-s", "--max-time", "4", `https://wttr.in/${city}?format=%c+%t`]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.text = text.trim()
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
