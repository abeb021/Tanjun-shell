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

    // 24-hour by default. The pin still wins when it is set, so a 12-hour
    // locale can be overridden one way or the other from config.
    readonly property bool hour12: !!Config.clock.twelveHour
    readonly property string time: {
        clock.date;
        hour12;
        return formatTime(tzId);
    }

    // Hour and minute as numbers, so a caller can lay the time out in its own
    // shape. They come out of the same formatter the one-line clock uses, so a
    // zone pin and the 12/24-hour setting cannot disagree between the two.
    readonly property var hhmm: {
        const bits = `${time}`.match(/(\d{1,2}):(\d{2})/);
        if (!bits)
            return { h: 0, m: 0 };
        return { h: Number(bits[1]), m: Number(bits[2]) };
    }

    readonly property string date: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
    readonly property string dateShort: Qt.formatDateTime(clock.date, "dd.MM")
    readonly property date now: clock.date

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function formatTime(tz) {
        const opts = {
            hour: "2-digit",
            minute: "2-digit",
            hour12: root.hour12
        };
        if (tz)
            opts.timeZone = tz;
        try {
            const s = clock.date.toLocaleTimeString("en-GB", opts);
            // Even "2-digit" drops the leading zero in some locales; a clock
            // that reads 8:39 instead of 08:39 looks broken next to one that
            // does not, so the hour is padded here rather than trusted.
            const bits = `${s}`.match(/(\d{1,2}):(\d{2})/);
            if (!bits)
                return s;
            const h = bits[1].length < 2 ? `0${bits[1]}` : bits[1];
            return `${h}:${bits[2]}${s.slice(bits[0].length)}`;
        } catch (e) {
            return Qt.formatDateTime(clock.date, "HH:mm");
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
