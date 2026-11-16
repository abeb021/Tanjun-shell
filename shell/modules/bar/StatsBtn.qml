import QtQuick
import "../widgets"
import "../../services"

// The bar's load readout, and the way into the stats menu. The glyphs match the
// sidebar's host row and each one is followed by its number, with a gap between
// the two pairs. Normal load reads like every other bar button; only the high
// thresholds tint it amber or red.
BarButton {
    id: root
    popoutName: "stats"
    // The vertical strip is only 40px wide, so the cpu pair is dropped there and
    // the ram readout is left on its own.
    property bool compact: false

    // The bar is the only reader that is always on screen, so it keeps the
    // sampler awake instead of waiting for the menu to be opened.
    Component.onCompleted: Host.barReading = true
    Component.onDestruction: Host.barReading = false

    BarText {
        visible: !root.compact
        text: "\uf2db"
        icon: true
        px: 13
        color: Theme.fg
    }
    BarText {
        visible: !root.compact
        text: Host.cpuText
        px: 11
        color: Theme.fg
    }
    // A gap between the cpu and ram pairs, so they do not read as one number.
    Item {
        visible: !root.compact
        width: 6
        height: 1
    }
    BarText {
        text: "\uefc5"
        icon: true
        px: 13
        color: Host.ramRatio >= 0.9 ? Theme.critical : (Host.ramRatio >= 0.75 ? Theme.warning : Theme.fg)
    }
    BarText {
        text: Host.ramShortText
        px: root.compact ? 10 : 11
        color: Host.ramRatio >= 0.9 ? Theme.critical : (Host.ramRatio >= 0.75 ? Theme.warning : Theme.fg)
    }
}
