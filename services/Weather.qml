pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string text: ""
    property bool live: false

    readonly property string query: Config.services.weatherCity.length ? encodeURIComponent(Config.services.weatherCity) : ""

    function refresh() {
        live = true;
        proc.running = true;
    }

    function ensure() {
        if (!live)
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
            if (root.live)
                root.refresh();
        }
    }

    Connections {
        target: ShellState
        function onLauncherOpenChanged() {
            if (ShellState.launcherOpen)
                root.ensure();
        }
        function onSidebarOpenChanged() {
            if (ShellState.sidebarOpen)
                root.ensure();
        }
        function onSettingsOpenChanged() {
            if (ShellState.settingsOpen)
                root.ensure();
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        running: root.live
        repeat: true
        onTriggered: proc.running = true
    }
}
