pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool ready: device && device.ready && device.isLaptopBattery
    readonly property real raw: device ? device.percentage : 0
    readonly property int percent: Math.round((raw > 1.5 ? raw : raw * 100))
    readonly property bool charging: {
        if (!device)
            return false;
        const s = `${device.state}`;
        return s.indexOf("Charg") >= 0 || s === "FullyCharged" || s === "2" || s === "4";
    }
}
