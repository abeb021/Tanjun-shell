import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../services"

PopupWindow {
    id: root

    required property string name
    required property Item anchorItem
    required property var barWindow

    default property alias popChildren: morph.data

    readonly property bool open: ShellState.popout === name
    visible: open || morph.opacity > 0.02
    grabFocus: open
    color: "transparent"
    anchor.window: barWindow
    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide

    onOpenChanged: if (open)
        escSink.forceActiveFocus()

    Item {
        id: escSink
        focus: true
        Keys.onEscapePressed: ShellState.closeMenus()
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: ShellState.closeMenus()
    }

    HyprlandFocusGrab {
        active: root.open
        windows: [root]
        onCleared: if (root.open && ShellState.popout === root.name)
            ShellState.closePopout()
    }

    Item {
        id: morph
        anchors.fill: parent
        transformOrigin: Item.TopLeft
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : Motion.popFrom

        Behavior on opacity {
            enabled: Motion.ready
            NumberAnimation {
                duration: Motion.pop
                easing.type: root.open ? Motion.easeOut : Motion.easeIn
            }
        }
        Behavior on scale {
            enabled: Motion.ready
            NumberAnimation {
                duration: Motion.pop
                easing.type: root.open ? Motion.easeOut : Motion.easeIn
            }
        }
    }
}
