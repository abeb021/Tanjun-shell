import QtQuick
import "../widgets"
import "../../services"

// The bar's memory readout, and the way into the load menu. No glyph: the
// numbers are the control, so the bar gains one short readout rather than
// another icon. Red past 90%, amber past 75%, the same thresholds the menu uses.
BarButton {
    id: root
    popoutName: "stats"
    // A vertical bar is 40px wide: "5.4G / 15G" cannot fit across it, so the
    // used figure alone is shown there and the full pair stays in the menu.
    property bool compact: false

    BarText {
        text: root.compact ? Host.ramShortText : Host.ramText
        px: root.compact ? 10 : 11
        color: Host.ramRatio >= 0.9 ? Theme.critical : (Host.ramRatio >= 0.75 ? Theme.warning : Theme.fgSub)
    }
}
