pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property int tzIndex: 0
    readonly property var zones: [
        { id: "Europe/Moscow", label: "Moscow" },
        { id: "Australia/Melbourne", label: "Melbourne" }
    ]
    readonly property var zone: zones[tzIndex]
    readonly property string tzId: zone.id
    readonly property string tzLabel: zone.label

    readonly property string time: formatTime(tzId)
    readonly property string timeFull: formatTime(tzId, true)
    readonly property string timeMoscow: formatTime("Europe/Moscow")
    readonly property string timeMelbourne: formatTime("Australia/Melbourne")
    readonly property string date: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
    readonly property string dateShort: Qt.formatDateTime(clock.date, "dd.MM")
    readonly property date now: clock.date

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    function formatTime(tz, withSeconds) {
        const opts = {
            timeZone: tz,
            hour: "2-digit",
            minute: "2-digit",
            hour12: false
        };
        if (withSeconds)
            opts.second = "2-digit";
        try {
            return clock.date.toLocaleTimeString("en-GB", opts);
        } catch (e) {
            return Qt.formatDateTime(clock.date, withSeconds ? "HH:mm:ss" : "HH:mm");
        }
    }

    function cycle(delta) {
        const n = zones.length;
        const step = delta === undefined || delta === 0 ? 1 : (delta > 0 ? 1 : -1);
        tzIndex = (tzIndex + step + n) % n;
    }
}
