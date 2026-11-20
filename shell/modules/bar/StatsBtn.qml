import QtQuick
import "../widgets"
import "../../services"

// The bar's load readout, and the way into the stats menu. The glyphs match the
// sidebar's host row and each one is followed by its number. Normal load reads
// like every other bar button; only the high thresholds tint it amber or red.
//
// Horizontal: one line — cpu pair, a gap, ram pair. Vertical: the same sizes
// stacked (cpu icon, cpu %, ram icon, ram usage), since the strip has height to
// spare where it has no width.
BarButton {
    id: root
    popoutName: "stats"
    property bool compact: false

    // The bar is the only reader that is always on screen, so it keeps the
    // sampler awake instead of waiting for the menu to be opened.
    Component.onCompleted: Host.barReading = true
    Component.onDestruction: Host.barReading = false

    readonly property color ramColor: Host.ramRatio >= 0.9 ? Theme.critical : (Host.ramRatio >= 0.75 ? Theme.warning : Theme.fg)

    // The stacked readout is taller than one line, so the button grows to fit it
    // (plus a little padding); the one-line readout keeps the usual bar height.
    implicitHeight: root.compact ? statsCol.implicitHeight + 6 : Theme.barHeight

    // Horizontal: one line.
    BarText {
        visible: !root.compact
        text: ""
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
        visible: !root.compact
        text: ""
        icon: true
        px: 13
        color: root.ramColor
    }
    BarText {
        visible: !root.compact
        text: Host.ramShortText
        px: 11
        color: root.ramColor
    }

    // Vertical: cpu icon, cpu %, ram icon, ram usage — the horizontal sizes,
    // stacked and centred in the strip.
    Column {
        id: statsCol
        visible: root.compact
        width: root.width
        spacing: 0

        BarText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: ""
            icon: true
            px: 13
            color: Theme.fg
        }
        BarText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Host.cpuText
            px: 11
            color: Theme.fg
        }
        // A little air between the cpu and ram groups, so they read as two
        // readouts rather than one four-line block.
        Item {
            width: 1
            height: 5
        }
        BarText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: ""
            icon: true
            px: 13
            color: root.ramColor
        }
        BarText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Host.ramShortText
            px: 11
            color: root.ramColor
        }
    }
}
