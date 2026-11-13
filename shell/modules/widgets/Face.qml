import QtQuick
import "../../services"

Rectangle {
    id: root

    property string job: "pop"
    property bool lit: false
    property bool danger: false
    // A surface that hangs off the bar: same material as the bar, square where
    // it meets the bar, rounded on the free edge, no line across the joint, so
    // the panel reads as the bar opening rather than a card floating over it.
    property bool attach: false
    // The caller draws frosted material behind this surface, so the surface
    // itself must stay transparent instead of painting its colour over it.
    property bool frosted: false
    // Which side the surface is attached to. Popups hang off the bar, so that is
    // the bar's edge; anything else attaches at the top as before.
    readonly property string attachEdge: (attach && job === "pop") ? Theme.barEdge : "top"
    property bool ticks: (job === "plane" && Theme.tick) || (job === "pop" && Theme.tickPops)

    readonly property int tickLen: job === "plane" ? Theme.tickPlane : Theme.tickPop
    readonly property int tickPad: job === "plane" ? Theme.tickPad : 8

    color: (frosted && Theme.glass) ? "transparent" : ((attach || job === "plane" || job === "strip") ? Theme.bg : Theme.surface)
    border.width: (attach || job === "strip") ? 0 : 1
    border.color: danger ? Theme.critical : (lit ? Theme.accent : (job === "plane" ? Theme.planeBorder : Theme.popBorder))
    radius: Theme.radius

    // square where it meets the bar, rounded on the free edge
    topLeftRadius: attach && (attachEdge === "top" || attachEdge === "left") ? 0 : radius
    topRightRadius: attach && (attachEdge === "top" || attachEdge === "right") ? 0 : radius
    bottomLeftRadius: attach && (attachEdge === "bottom" || attachEdge === "left") ? 0 : radius
    bottomRightRadius: attach && (attachEdge === "bottom" || attachEdge === "right") ? 0 : radius

    Repeater {
        model: root.ticks ? 4 : 0
        Rectangle {
            required property int index
            z: 8
            width: index % 2 === 0 ? root.tickLen : Theme.tickArm
            height: index % 2 === 0 ? Theme.tickArm : root.tickLen
            color: Theme.accent
            anchors.top: index < 2 ? parent.top : undefined
            anchors.left: index < 2 ? parent.left : undefined
            anchors.bottom: index >= 2 ? parent.bottom : undefined
            anchors.right: index >= 2 ? parent.right : undefined
            anchors.margins: root.tickPad
        }
    }
}
