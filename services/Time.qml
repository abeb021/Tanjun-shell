pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property int tzIndex: 0
    readonly property var zones: Config.clockZones
    readonly property var zone: {
        const z = zones;
        if (!z || !z.length)
            return { id: Config.localId, label: Config.localLabel };
        const i = Math.max(0, Math.min(z.length - 1, tzIndex));
        return z[i];
    }
    readonly property string tzId: zone.id || Config.localId
    readonly property string tzLabel: zone.label || Config.prettyZone(tzId)

    readonly property string time: formatTime(tzId)
    readonly property string timeFull: formatTime(tzId, true)
    readonly property string date: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
    readonly property string dateShort: Qt.formatDateTime(clock.date, "dd.MM")
    readonly property date now: clock.date

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    function formatTime(tz, withSeconds) {
        const opts = {
            hour: "2-digit",
            minute: "2-digit",
            hour12: !!Config.clock.twelveHour
        };
        if (tz)
            opts.timeZone = tz;
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
        if (!n)
            return;
        const step = delta === undefined || delta === 0 ? 1 : (delta > 0 ? 1 : -1);
        tzIndex = (tzIndex + step + n) % n;
    }
}
