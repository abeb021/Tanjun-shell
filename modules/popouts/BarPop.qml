import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../services"

PopupWindow {
    id: root

    required property string name
    required property Item anchorItem
    required property var barWindow

    visible: ShellState.popout === name
    grabFocus: true
    color: "transparent"
    anchor.window: barWindow
    anchor.item: anchorItem
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide

    onVisibleChanged: if (visible)
        escSink.forceActiveFocus()

    Item {
        id: escSink
        focus: true
        Keys.onEscapePressed: ShellState.closeMenus()
    }

    Shortcut {
        sequence: "Escape"
        onActivated: ShellState.closeMenus()
    }

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onCleared: if (ShellState.popout === root.name)
            ShellState.closePopout()
    }
}
