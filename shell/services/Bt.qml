pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter ? adapter.enabled : false
    readonly property bool scanning: adapter ? adapter.discovering : false
    readonly property var devices: adapter && adapter.devices ? adapter.devices : []

    function toggle() {
        if (!adapter)
            return;
        const next = !adapter.enabled;
        if (!next)
            scan(false);
        adapter.enabled = next;
    }

    function connected(dev) {
        return !!(dev && dev.state === BluetoothDeviceState.Connected);
    }

    function scan(on) {
        if (!adapter || !adapter.enabled)
            return;
        adapter.discovering = !!on;
    }

    function act(dev) {
        if (!dev)
            return;
        if (dev.state === BluetoothDeviceState.Connected) {
            dev.disconnect();
            return;
        }
        scan(false);
        dev.trusted = true;
        dev.connect();
    }

    function label(dev) {
        if (!dev)
            return "";
        if (dev.pairing)
            return "pairing";
        if (dev.state === BluetoothDeviceState.Connected)
            return "disconnect";
        if (dev.state === BluetoothDeviceState.Connecting)
            return "connecting";
        if (dev.state === BluetoothDeviceState.Disconnecting)
            return "disconnecting";
        return "connect";
    }
}
