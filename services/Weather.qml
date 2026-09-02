pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string text: ""

    readonly property string query: Config.services.weatherCity.length ? encodeURIComponent(Config.services.weatherCity) : ""

    function refresh() {
        proc.running = true;
    }

    Process {
        id: proc
        command: ["curl", "-s", "--max-time", "4", `https://wttr.in/${root.query}?format=%c+%t`]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.text = text.trim()
        }
    }

    Connections {
        target: Config.services
        function onWeatherCityChanged() {
            root.refresh();
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
