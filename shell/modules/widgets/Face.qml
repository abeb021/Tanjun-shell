import QtQuick
import "../../services"

Rectangle {
    id: root

    property string job: "pop"
    property bool lit: false
    property bool danger: false
    // A surface that hangs off the bar: same material as the bar, square top edge,
    // no line across the joint, so the panel reads as the bar opening rather than
    // a card floating over it.
    property bool attach: false
    property bool ticks: (job === "plane" && Theme.tick) || (job === "pop" && Theme.tickPops)

    readonly property int tickLen: job === "plane" ? Theme.tickPlane : Theme.tickPop
    readonly property int tickPad: job === "plane" ? Theme.tickPad : 8

    color: (attach || job === "plane" || job === "strip") ? Theme.bg : Theme.surface
    border.width: (attach || job === "strip") ? 0 : 1
    border.color: danger ? Theme.critical : (lit ? Theme.accent : (job === "plane" ? Theme.planeBorder : Theme.popBorder))
    radius: Theme.radius

    // square where it meets the bar, rounded on the free edge
    topLeftRadius: attach ? 0 : radius
    topRightRadius: attach ? 0 : radius
    bottomLeftRadius: radius
    bottomRightRadius: radius

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
