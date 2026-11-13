import QtQuick
import Quickshell
import "../widgets"
import "../../services"

// A bar menu: a panel hanging off the bar's bottom edge, uncovered downward by a
// damped spring so it grows past its final size by a hair and settles.
//
// The window *is* the panel — same size and same place from the first frame to
// the last — so no compositor ever sees a resize to animate, and the panel has
// no coordinates of its own inside it that could disagree with the window's.
OverlayHost {
    id: root

    required property string name
    required property Item anchorItem
    required property var barWindow
    // Which point of the anchor the panel hangs from: Top centres it, TopRight
    // aligns its right edge to the anchor (the usual case for a right-hand menu).
    property int align: Item.TopLeft
    property real cardW: 280
    property real cardH: 200
    // Content is loaded on first open and unloaded after close, while the window
    // stays mapped: the compositor never sees a map/unmap, so it never animates
    // the popup. Keeping the surface costs a pixel of buffer, keeping the QML tree
    // costs tens of megabytes.
    property string source: ""
    property bool everOpen: false

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
    // popups own their own motion: keep the surface mapped so the compositor
    // never animates the open or the close
    keepMapped: true
    panelSized: true
    // opacity is constant now, so keep the surface up while the spring retracts
    contentOpacity: (root.open || reveal.value > 0.001) ? 1 : 0

    onOpenChanged: {
        if (open) {
            everOpen = true;
            // the panel is already at its place; only measure once in case the
            // bar has been re-laid out since the last open
            root.measure();
            Qt.callLater(() => {
                if (!root.open)
                    return;
                root.measure();
                morph.revealed = true;
                morph.forceActiveFocus();
            });
        } else {
            morph.revealed = false;
        }
    }
    onAnchorItemChanged: measure()
    onCardWChanged: measure()
    onCardHChanged: measure()
    onScreenChanged: measure()

    // Work out where the panel goes, in screen-local pixels, and hand that to the
    // surface. Only the *window* is positioned; the panel fills it.
    function measure() {
        const scr = root.screen;
        if (!anchorItem || !scr)
            return;
        const w = Math.ceil(root.cardW);
        const h = Math.ceil(root.cardH);
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
        root.panelWidth = w;
        root.panelHeight = h;
        root.panelX = Math.round(Math.max(8, Math.min(x, maxX)));
        root.panelY = Math.round(Math.max(Theme.barHeight - overlap, sy - overlap));
        root.reportPop();
    }

    function reportPop() {
        UiMode.popGrow = "down";
        UiMode.popFromY = Motion.popY;
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: UiMode.closeMenus()
    }

    // The reveal is the *clip*, not a motion: the panel is drawn at full size and
    // uncovered from its top edge downward. x and width never change, so the panel
    // cannot arrive from a side.
    SpringProgress {
        id: reveal
        open: morph.revealed
    }

    Item {
        id: morph
        property bool revealed: false
        // The window is the panel, so the panel starts at its origin.
        x: 0
        y: 0
        width: root.cardW
        height: Math.round(root.cardH * reveal.value)
        clip: true
        focus: true
        Keys.onEscapePressed: UiMode.closeMenus()

        Component.onCompleted: Qt.callLater(() => {
            root.reportPop();
            root.measure();
            revealed = root.open;
        })

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

            Loader {
                anchors.fill: parent
                active: root.everOpen && (root.open || root.contentOpacity > 0.02)
                source: root.source.length ? Qt.resolvedUrl(root.source) : ""
                onLoaded: {
                    if (!item)
                        return;
                    root.cardW = item.implicitWidth > 0 ? item.implicitWidth : root.cardW;
                    root.cardH = item.implicitHeight > 0 ? item.implicitHeight : root.cardH;
                    root.measure();
                }
            }
        }
    }
}
