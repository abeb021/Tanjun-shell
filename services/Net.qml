pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string ssid: ""
    property int signal: 0
    property bool connected: false
    readonly property string text: connected ? (ssid || "wifi") : "offline"

    function refresh() {
        proc.running = true;
    }

    Process {
        id: proc
        command: ["bash", "-c", `${Quickshell.env("HOME")}/.config/waybar/scripts/wifi.sh`]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text.trim().split("\n").pop());
                    const t = j.text || "";
                    root.connected = t.indexOf("󰤭") < 0 && t !== "";
                    const parts = t.split(" ");
                    root.ssid = parts.length > 1 ? parts.slice(1).join(" ") : t;
                } catch (e) {
                    root.connected = false;
                    root.ssid = "";
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
