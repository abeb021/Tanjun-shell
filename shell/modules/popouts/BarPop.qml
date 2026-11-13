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
    // opacity is constant now, so keep the surface up while the spring retracts
    contentOpacity: (root.open || morph.height > 1) ? 1 : 0

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
        // Overlap the bar's last row by a pixel: the panel is the bar's own
        // material, so covering the edge (including the chrome rule) makes the
        // two read as one surface instead of a card with a line across it.
        const overlap = 1;
        morph.x = Math.round(Math.max(8, Math.min(x, maxX)));
        morph.y = Math.round(Math.max(Theme.barHeight - overlap, sy - overlap));
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

    // Serpantinum's reveal: the panel is *pulled out of the bar* by a damped
    // spring, so it grows past its final size by a hair and settles. Its top edge
    // never moves, and nothing fades — the surface is simply uncovered downward.
    SpringProgress {
        id: reveal
        open: morph.revealed
    }

    Item {
        id: morph
        property bool revealed: false
        width: root.cardW
        height: Math.round(root.cardH * reveal.value)
        clip: true
        opacity: 1
        focus: true
        Keys.onEscapePressed: UiMode.closeMenus()

        Component.onCompleted: Qt.callLater(() => {
            root.reportPop();
            root.place();
            revealed = root.open;
        })

        transform: Slide {
            open: morph.revealed
            fromY: 0
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


    }
}
