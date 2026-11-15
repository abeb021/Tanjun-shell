import QtQuick
import "../widgets"
import "../../services"

BarButton {
    id: root
    popoutName: "clock"
    // A vertical bar is 40px across, which a full `08:39` at the configured
    // size does not fit. There the time is split at the colon and stacked, so
    // each column stays narrow instead of the strip growing to hold one label.
    property bool compact: false
    onRightClicked: Time.cycle()
    onMiddleClicked: Time.tzIndex = 0
    onWheeled: steps => Time.cycle(steps)

    // Both halves come out of the one formatted time, padded to two digits.
    readonly property string hh: pad(Time.hhmm.h)
    readonly property string mm: pad(Time.hhmm.m)

    // Only the clock gets a taller hit area on a vertical bar: the stacked pair
    // needs the room, where every other button stays `barHeight` tall.
    implicitHeight: root.compact ? Theme.barThickness : Theme.barHeight

    function pad(n) {
        const s = `${Number(n) || 0}`;
        return s.length < 2 ? `0${s}` : s;
    }

    // Horizontal bar: one line, as before.
    BarText {
        visible: !root.compact
        text: Time.time
        px: Theme.fontPx
    }

    // Vertical bar: hours over minutes. Both halves are the body colour — one
    // time, not a primary and a secondary line. 12px still fits two digits in the
    // 40px strip; 10px read small next to the rest of the bar.
    Column {
        visible: root.compact
        spacing: -4
        BarText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.hh
            px: 16
        }
        BarText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.mm
            px: 16
        }
    }
}
