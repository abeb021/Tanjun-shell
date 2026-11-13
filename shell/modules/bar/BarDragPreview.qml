import QtQuick
import Quickshell
import Quickshell.Wayland
import "../widgets"
import "../../services"

// Full-screen, input-transparent preview shown while the bar is dragged: a
// ghost bar follows the pointer and a band marks the edge it will snap to.
PanelWindow {
    id: root

    property var screenObj: null

    screen: screenObj
    visible: UiMode.barDragging && !!screenObj && UiMode.barDragScreen === `${screenObj.name}`
    color: "transparent"
    focusable: false
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: -1
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    mask: Region {
        width: 0
        height: 0
    }

    WlrLayershell.namespace: "tanjun-bar-drag"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property string edge: UiMode.barDragEdge
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property real ghostW: vertical ? Theme.barThickness : Math.min(260, root.width * 0.45)
    readonly property real ghostH: vertical ? Math.min(260, root.height * 0.45) : Theme.barHeight
    readonly property real gx: Math.max(ghostW / 2 + 14, Math.min(root.width - ghostW / 2 - 14, UiMode.barDragX))
    readonly property real gy: Math.max(ghostH / 2 + 14, Math.min(root.height - ghostH / 2 - 14, UiMode.barDragY))

    Rectangle {
        x: root.edge === "right" ? root.width - width : 0
        y: root.edge === "bottom" ? root.height - height : 0
        width: root.vertical ? Theme.barThickness : root.width
        height: root.vertical ? root.height : Theme.barThickness
        color: Theme.wash(Theme.accent, 0.10)
    }

    Rectangle {
        x: root.edge === "right" ? root.width - width : 0
        y: root.edge === "bottom" ? root.height - height : 0
        width: root.vertical ? 2 : root.width
        height: root.vertical ? root.height : 2
        color: Theme.accent
    }

    Rectangle {
        x: root.gx - width / 2
        y: root.gy - height / 2
        width: root.ghostW
        height: root.ghostH
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.accent

        BarText {
            anchors.centerIn: parent
            text: Theme.tan.length ? Theme.tan : "•"
            role: "seal"
            px: 18
        }
    }
}
