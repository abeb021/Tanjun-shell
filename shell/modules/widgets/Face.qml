import QtQuick
import "../../services"

Rectangle {
    id: root

    property string job: "pop"
    property bool lit: false
    property bool danger: false
    // A surface that hangs off the bar: same material as the bar, square where
    // it meets the bar, rounded on the free edge, so the panel reads as the bar
    // opening rather than a card floating over it.
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

    color: (frosted && Theme.glass) ? Theme.glassSurface : ((attach || job === "plane" || job === "strip") ? Theme.bg : Theme.surface)
    // A free card is outlined on all four sides by its own border. An attached
    // menu cannot use it: the edge it shares with the bar must carry no line, and
    // a Rectangle border covers four sides at once (see `attachFrame`).
    border.width: (attach || job === "strip") ? 0 : 1
    border.color: danger ? Theme.critical : (lit ? Theme.accent : (job === "plane" ? Theme.planeBorder : Theme.popBorder))
    radius: Theme.radius

    readonly property int attachEdgeWidth: attach ? Theme.attachBorderWidth : 0
    readonly property color edgeColor: danger ? Theme.critical : (lit ? Theme.accent : Theme.attachBorder)

    // square where it meets the bar, rounded on the free edge
    topLeftRadius: attach && (attachEdge === "top" || attachEdge === "left") ? 0 : radius
    topRightRadius: attach && (attachEdge === "top" || attachEdge === "right") ? 0 : radius
    bottomLeftRadius: attach && (attachEdge === "bottom" || attachEdge === "left") ? 0 : radius
    bottomRightRadius: attach && (attachEdge === "bottom" || attachEdge === "right") ? 0 : radius

    // The outline of an attached menu: a normal Rectangle border, extended by one
    // border-width toward the bar only. Rectangle draws its border inside the
    // rect, so the shared edge's line lands inside the bar strip, where the bar's
    // own fill covers it, and the three free edges stay on the card's outline.
    // Extending the other way would leave that line visible between the two — the
    // 1px seam this exists to avoid.
    Rectangle {
        id: attachFrame
        visible: root.attachEdgeWidth > 0
        // Above the content: the outline is the outermost pixel, and a section
        // spanning the full width would otherwise paint over it.
        z: 5
        readonly property real bleed: root.attachEdgeWidth
        color: "transparent"
        border.width: root.attachEdgeWidth
        border.color: root.edgeColor
        radius: Theme.radius
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius

        // Extended by one border-width toward the bar only. The border that would
        // otherwise sit on the shared edge is pushed into the strip, where the bar
        // covers it; the free edges stay exactly on the card's own outline.
        anchors.fill: parent
        anchors.topMargin: root.attachEdge === "top" ? -bleed : 0
        anchors.bottomMargin: root.attachEdge === "bottom" ? -bleed : 0
        anchors.leftMargin: root.attachEdge === "left" ? -bleed : 0
        anchors.rightMargin: root.attachEdge === "right" ? -bleed : 0
    }

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
