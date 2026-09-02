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
        const s = device.state;
        if (s === UPowerDeviceState.Charging || s === UPowerDeviceState.FullyCharged || s === UPowerDeviceState.PendingCharge)
            return true;
        if (s === UPowerDeviceState.Discharging || s === UPowerDeviceState.PendingDischarge || s === UPowerDeviceState.Empty)
            return false;
        return !UPower.onBattery;
    }
    readonly property string icon: {
        if (charging)
            return "󰂄";
        const idle = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        const i = Math.max(0, Math.min(10, Math.round(percent / 10)));
        return idle[i];
    }
}
