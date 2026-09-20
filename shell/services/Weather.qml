pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string text: ""
    readonly property bool wanted: UiMode.launcherOpen || (UiMode.settingsOpen && SettingsNav.page === "weather")
    readonly property bool live: wanted

    readonly property string query: Config.services.weatherCity.length ? encodeURIComponent(Config.services.weatherCity) : ""

    function refresh() {
        proc.running = true;
    }

    function ensure() {
        if (wanted)
            refresh();
    }

    Process {
        id: proc
        command: ["curl", "-s", "--max-time", "4", `https://wttr.in/${root.query}?format=%c+%t`]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.text = text.trim()
        }
    }

    Connections {
        target: Config.services
        function onWeatherCityChanged() {
            if (root.wanted)
                root.refresh();
        }
    }

    onWantedChanged: if (wanted)
        root.refresh()

    Timer {
        interval: 15 * 60 * 1000
        running: root.wanted
        repeat: true
        onTriggered: proc.running = true
    }
}
