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

    readonly property var networks: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : []

    // One scan at startup so the menu already has rows the first time it opens:
    // the radio only scans while something watches it, and a list that fills in
    // after the card has rolled out changes its height under the pointer.
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
    readonly property bool watching: UiMode.sidebarOpen || UiMode.popout === "network" || (UiMode.settingsOpen && SettingsNav.page === "network")

    function signalIcon(n) {
        if (!n || n.signalStrength === undefined)
            return "󰖩";
        let s = Number(n.signalStrength);
        if (!isFinite(s) || s < 0)
            return "󰖩";
        if (s > 1)
            s = s / 100;
        if (s >= 0.75)
            return "󰤨";
        if (s >= 0.5)
            return "󰤥";
        if (s >= 0.25)
            return "󰤢";
        if (s > 0.05)
            return "󰤟";
        return "󰤯";
    }

    function secured(n) {
        if (!n || n.security === undefined)
            return false;
        return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Unknown;
    }

    function setScanning(on) {
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
