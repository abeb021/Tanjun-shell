import QtQuick
import Quickshell
import "../widgets"
import "../../services"

// A bar menu: a card that rolls out of the bar.
//
// The surface the card lives in is pinned to the bar's edge once, when it is
// created, and spans the bar. Its rect never changes afterwards, so opening a
// menu only moves the card *inside* it, in plain item coordinates: no margins
// are re-pinned, no configure round-trip happens, and the compositor already
// knows where the panel is before the first click. That is what keeps the first
// open from hopping into place.
//
// The content is instantiated for the whole session, so the card knows its size
// before the click and the reveal is the only thing that animates.
OverlayHost {
    id: root

    required property string name
    required property Item anchorItem
    required property var barWindow
    // Which point of the anchor the panel hangs from: Top centres it, TopRight
    // aligns its right edge to the anchor (the usual case for a right-hand menu).
    property int align: Item.TopLeft
    property string source: ""
    property real cardW: 280
    property real cardH: 200
    // What the content needs (cardH) and what is on screen (shownH). A size
    // change that arrives while the panel is open is grown into: the surface is
    // already up, so only the card has to move.
    property real shownH: cardH

    Behavior on shownH {
        enabled: root.open && Motion.kind !== "instant"
        NumberAnimation {
            duration: Motion.fast
            easing.type: Easing.OutQuad
        }
    }

    readonly property string edge: Theme.barEdge
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property int bar: Theme.barThickness
    readonly property real spanW: root.screen ? root.screen.width : 1
    readonly property real spanH: root.screen ? root.screen.height : 1
    // Every menu caps itself at 440 px; the surface reaches past that so a card
    // can never be clipped by the window it lives in.
    readonly property real depth: Math.max(1, Math.min(root.vertical ? root.spanW - root.bar : root.spanH - root.bar, 600))

    // Fixed for the session: the panel starts where the bar ends and reaches far
    // enough for the tallest menu, so no size is ever requested from the
    // compositor after creation and the closed surfaces stay small.
    panelSized: true
    panelEdge: root.edge
    panelInset: root.bar - 1
    panelDepth: root.depth
    panelHotItem: morph

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

    // The button's place in output coordinates. The bar's clusters are direct
    // children of its content item, so the offset of the cluster plus the offset
    // of the button inside it is the screen position. Reading both properties
    // keeps this live when either moves — the right-hand cluster shifts left as
    // the tray grows.
    readonly property var anchorSpot: {
        const item = root.anchorItem;
        if (!item || !root.barWindow || !root.screen)
            return Qt.point(0, 0);
        const p = item.parent;
        const x = item.x + (p ? p.x : 0);
        const y = item.y + (p ? p.y : 0);
        const originX = root.edge === "right" ? root.spanW - root.bar : 0;
        const originY = root.edge === "bottom" ? root.spanH - root.bar : 0;
        return Qt.point(x + originX, y + originY);
    }
    readonly property real anchorLen: root.anchorItem
        ? (root.vertical ? root.anchorItem.height : root.anchorItem.width)
        : 0

    // Where the card sits along the bar. Screen coordinates, because the surface
    // spans the whole bar on that axis.
    readonly property real cardAlong: {
        const spot = root.anchorSpot;
        const len = root.anchorLen;
        if (root.vertical)
            return spot.y + len / 2 - root.cardH / 2;
        if (root.align === Item.TopRight)
            return spot.x + len - root.cardW;
        if (root.align === Item.Top)
            return spot.x + (len - root.cardW) / 2;
        return spot.x;
    }

    onOpenChanged: {
        if (!open)
            return;
        adoptSize();
        reportPop();
        morph.forceActiveFocus();
    }
    onEdgeChanged: reportPop()

    function reportPop() {
        UiMode.popGrow = root.edge === "top" ? "down" : (root.edge === "bottom" ? "up" : (root.edge === "left" ? "right" : "left"));
        UiMode.popFromY = root.vertical ? 0 : Motion.popY;
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: UiMode.closeMenus()
    }

    // The reveal uncovers the card from the bar's edge with the spring.
    SpringProgress {
        id: reveal
        open: root.open
    }

    Item {
        id: morph
        // The clip grows out of the bar; the outer edge stays put.
        width: root.vertical ? Math.round(root.cardW * reveal.value) : root.cardW
        height: root.vertical ? root.shownH : Math.round(root.shownH * reveal.value)
        x: root.vertical
            ? Math.round(root.edge === "right" ? root.depth - width : 0)
            : Math.round(Math.max(8, Math.min(root.cardAlong, root.spanW - root.cardW - 8)))
        y: root.vertical
            ? Math.round(Math.max(8, Math.min(root.cardAlong, root.spanH - root.shownH - 8)))
            : Math.round(root.edge === "bottom" ? root.depth - height : 0)
        clip: true
        focus: true
        Keys.onEscapePressed: UiMode.closeMenus()

        MouseArea {
            z: -1
            width: root.cardW
            height: root.shownH
            onClicked: {}
        }

        Item {
            id: slot
            // The content never moves: it sits at the outer edge of the card and
            // the clip uncovers it. Both offsets are in terms of the same
            // animated size as the clip, so the two stay glued at every frame.
            x: root.vertical ? (root.edge === "right" ? morph.width - root.cardW : 0) : 0
            y: root.vertical ? 0 : (root.edge === "bottom" ? morph.height - root.shownH : 0)
            width: root.cardW
            height: root.shownH

            Loader {
                id: pop
                anchors.fill: parent
                active: true
                source: root.source.length ? Qt.resolvedUrl(root.source) : ""
                onLoaded: root.adoptSize()
            }
        }
    }

    // The content lives for the whole session, so its size is followed all the
    // time: a change while the panel is closed is already accounted for by the
    // time it opens, and opening never waits for a layout pass. A change while
    // it is open animates the card instead of moving it by a jump.
    function adoptSize() {
        const item = pop.item;
        if (!item)
            return;
        const w = Math.ceil(item.implicitWidth);
        const h = Math.ceil(item.implicitHeight);
        if (w > 0 && w !== Math.ceil(root.cardW))
            root.cardW = w;
        if (h > 0 && h !== Math.ceil(root.cardH))
            root.cardH = h;
    }

    Connections {
        target: pop.item
        ignoreUnknownSignals: true
        function onImplicitWidthChanged() {
            root.adoptSize();
        }
        function onImplicitHeightChanged() {
            root.adoptSize();
        }
    }
}
