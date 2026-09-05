import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: root

    required property string name
    required property Item anchorItem
    required property var barWindow
    property int growFrom: Item.TopLeft
    property real cardW: 280
    property real cardH: 200

    default property alias popChildren: slot.data

    readonly property bool open: ShellState.popout === name
    readonly property bool shown: open || morph.opacity > 0.02

    screen: barWindow ? barWindow.screen : null
    visible: shown
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: -1
    focusable: true

    WlrLayershell.namespace: "tanjun-pop-" + name
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    onOpenChanged: if (open) {
        root.place();
        Qt.callLater(root.place);
        morph.forceActiveFocus();
    }
    onCardWChanged: if (open)
        place()
    onCardHChanged: if (open)
        place()

    function place() {
        const scr = root.screen;
        if (!anchorItem || !scr)
            return;
        const w = root.cardW;
        const h = root.cardH;
        if (w < 1 || h < 1)
            return;
        const g = anchorItem.mapToGlobal(0, 0);
        const sx = g.x - scr.x;
        const sy = g.y - scr.y + anchorItem.height;
        let x = sx;
        if (growFrom === Item.TopRight)
            x = sx + anchorItem.width - w;
        else if (growFrom === Item.Top)
            x = sx + (anchorItem.width - w) / 2;
        const maxX = scr.width - w - 8;
        morph.x = Math.round(Math.max(8, Math.min(x, maxX)));
        morph.y = Math.round(Math.max(Theme.barHeight, sy));
        morph.width = w;
        morph.height = h;
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: ShellState.closeMenus()
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.open
        onClicked: ShellState.closeMenus()
    }

    Item {
        id: morph
        width: root.cardW
        height: root.cardH
        transformOrigin: root.growFrom
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : Motion.popFrom
        focus: true
        Keys.onEscapePressed: ShellState.closeMenus()

        MouseArea {
            z: -1
            anchors.fill: parent
            onClicked: {}
        }

        Item {
            id: slot
            anchors.fill: parent
        }

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
