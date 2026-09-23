import QtQuick
import Quickshell
import "../widgets"
import "../../services"

OverlayHost {
    id: root

    required property string name
    required property Item anchorItem
    required property var barWindow
    property int align: Item.TopLeft
    property real cardW: 280
    property real cardH: 200

    default property alias popChildren: slot.data

    screen: barWindow ? barWindow.screen : null
    onThisScreen: {
        const want = UiMode.popoutScreen;
        const mine = barWindow && barWindow.screen ? `${barWindow.screen.name}` : "";
        if (!want.length)
            return Compositor.isScreenFocused(barWindow ? barWindow.screen : null);
        return mine === want;
    }
    open: UiMode.popout === name && onThisScreen
    layerName: "tanjun-pop-" + name
    dismissOthers: true
    contentOpacity: morph.opacity

    onOpenChanged: {
        if (open) {
            root.place();
            Qt.callLater(() => {
                if (!root.open)
                    return;
                root.place();
                morph.revealed = true;
                morph.forceActiveFocus();
            });
        } else {
            morph.revealed = false;
        }
    }
    onAnchorItemChanged: if (open)
        place()
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
        if (align === Item.TopRight)
            x = sx + anchorItem.width - w;
        else if (align === Item.Top)
            x = sx + (anchorItem.width - w) / 2;
        const maxX = scr.width - w - 8;
        morph.x = Math.round(Math.max(8, Math.min(x, maxX)));
        morph.y = Math.round(Math.max(Theme.barHeight, sy));
        morph.width = w;
        root.reportPop();
    }

    function reportPop() {
        UiMode.popGrow = "down";
        UiMode.popOrigin = "top";
        UiMode.popScaleX = 1;
        UiMode.popFromY = -Motion.popY;
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: UiMode.closeMenus()
    }

    Item {
        id: morph
        property bool revealed: false
        width: root.cardW
        height: revealed ? root.cardH : 0
        clip: true
        opacity: revealed ? 1 : 0
        focus: true
        Keys.onEscapePressed: UiMode.closeMenus()

        Component.onCompleted: Qt.callLater(() => {
            root.reportPop();
            root.place();
            revealed = root.open;
        })

        transform: Slide {
            open: morph.revealed
            fromY: -Motion.popY
            duration: Motion.pop
        }

        MouseArea {
            z: -1
            width: root.cardW
            height: root.cardH
            onClicked: {}
        }

        Item {
            id: slot
            width: root.cardW
            height: root.cardH
        }

        Behavior on height {
            enabled: Motion.ready
            NumberAnimation {
                duration: Motion.pop
                easing.type: morph.revealed ? Motion.easeOut : Motion.easeIn
            }
        }
        Behavior on opacity {
            enabled: Motion.ready
            NumberAnimation {
                duration: Motion.pop
                easing.type: morph.revealed ? Motion.enterEase : Motion.easeIn
            }
        }
    }
}
