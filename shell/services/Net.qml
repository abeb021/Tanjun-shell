pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Singleton {
    id: root

    readonly property var wifiDevice: {
        const list = Networking.devices.values;
        if (!list)
            return null;
        for (let i = 0; i < list.length; i++) {
            if (list[i].type === DeviceType.Wifi)
                return list[i];
        }
        return null;
    }

    readonly property var connectedNet: {
        const dev = wifiDevice;
        if (!dev || !dev.networks)
            return null;
        const nets = dev.networks.values;
        if (!nets)
            return null;
        for (let i = 0; i < nets.length; i++) {
            if (nets[i].connected)
                return nets[i];
        }
        return null;
    }

    readonly property var liveNetworks: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : []
    // The scan list exists only while something watches it, and it collapses back
    // to the connected network when the radio stops scanning. Only the count is
    // remembered here: the network objects die with the scan, so the menu reserves
    // its height from the number and fills it in again on open.
    property int seenRows: 0
    readonly property var networks: liveNetworks

    onLiveNetworksChanged: {
        if (!(watching || scanning) || !liveNetworks)
            return;
        if (liveNetworks.length > seenRows)
            seenRows = liveNetworks.length;
    }

    // One scan at startup so the menu knows how tall its list will be before the
    // first click: it is only scanned while something watches it, and the panel
    // must not grow a row after it has already rolled out.
    Component.onCompleted: warmUp.start()

    onWifiOnChanged: {
        if (wifiOn)
            warmUp.restart();
    }

    Timer {
        id: warmUp
        interval: 900
        onTriggered: {
            if (!watching && wifiOn && wifiDevice) {
                setScanning(true);
                warmDown.start();
            }
        }
    }

    Timer {
        id: warmDown
        interval: 4000
        onTriggered: {
            if (!watching)
                setScanning(false);
        }
    }

    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property bool connected: !!(connectedNet || (wifiDevice && wifiDevice.connected))
    readonly property string ssid: connectedNet ? (connectedNet.name || "") : ""
    readonly property string text: connected ? (ssid || "wifi") : (wifiOn ? "wifi" : "offline")

    property string vpn: ""
    readonly property bool vpnUp: vpn.length > 0
    property bool scanning: false
    readonly property bool watching: UiMode.sidebarOpen || UiMode.popout === "network" || (UiMode.settingsOpen && SettingsNav.page === "network")

    function setScanning(on) {
        scanning = !!on;
        if (wifiDevice && wifiDevice.scannerEnabled !== undefined)
            wifiDevice.scannerEnabled = on;
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function connectNet(n, password) {
        if (!n)
            return;
        if (n.connected) {
            n.disconnect();
            return;
        }
        if (password && `${password}`.length) {
            if (n.connectWithPsk)
                n.connectWithPsk(`${password}`);
            else
                n.connect();
            return;
        }
        n.connect();
    }

    function refreshVpn() {
        vpnProc.running = true;
    }

    Process {
        id: vpnProc
        command: ["bash", "-c", "nmcli -t -f TYPE,NAME connection show --active 2>/dev/null | awk -F: '$1 ~ /vpn|wireguard|tun|sstp|amnezia/ {print $2; exit}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.vpn = text.trim()
        }
    }

    Timer {
        interval: 15000
        running: root.watching
        repeat: true
        onTriggered: root.refreshVpn()
    }

    onWatchingChanged: {
        if (watching) {
            warmDown.stop();
            root.refreshVpn();
        }
    }
}
