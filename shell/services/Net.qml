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
    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property bool connected: !!(connectedNet || (wifiDevice && wifiDevice.connected))
    readonly property string ssid: connectedNet ? (connectedNet.name || "") : ""
    readonly property string text: connected ? (ssid || "wifi") : (wifiOn ? "wifi" : "offline")

    property string vpn: ""
    readonly property bool vpnUp: vpn.length > 0

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
        const ssid = `${n.name || ""}`;
        if (password && `${password}`.length && ssid.length) {
            Quickshell.execDetached(["nmcli", "device", "wifi", "connect", ssid, "password", `${password}`]);
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
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.vpn = text.trim()
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.refreshVpn()
    }
}
