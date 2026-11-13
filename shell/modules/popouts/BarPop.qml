import QtQuick
import "../widgets"
import "../../services"

// A bar menu: a card that rolls out of the bar.
//
// It is an item inside the bar's own window, so the bar and its menus are one
// surface. Opening a menu moves the card in item coordinates only — no window is
// created, moved, resized or re-anchored — and the joint between the bar and the
// card is not a compositor seam. The content is instantiated for the whole
// session, so the card knows its size before the click.
Item {
    id: root

    required property string name
    required property Item anchorItem
    // The bar's strip, the part of the window the bar itself occupies. The card
    // hangs off it and the button's position is expressed relative to the window
    // through it.
    required property Item strip
    required property var barWindow
    // Which point of the anchor the panel hangs from: Top centres it, TopRight
    // aligns its right edge to the anchor (the usual case for a right-hand menu).
    property int align: Item.TopLeft
    property string source: ""
    property real cardW: 280
    property real cardH: 200
    // What the content needs (cardH) and what is on screen (shownH). A size
    // change that arrives while the panel is open is grown into: only the card
    // moves, and the window around it is not touched.
    property real shownH: cardH

    anchors.fill: parent

    readonly property string edge: Theme.barEdge
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property int bar: Theme.barThickness
    readonly property var screen: barWindow ? barWindow.screen : null
    readonly property real spanW: screen ? screen.width : 1
    readonly property real spanH: screen ? screen.height : 1

    readonly property bool onThisScreen: {
        const want = UiMode.popoutScreen;
        const mine = barWindow && barWindow.screen ? `${barWindow.screen.name}` : "";
        if (!want.length)
            return Compositor.isScreenFocused(barWindow ? barWindow.screen : null);
        return mine === want;
    }
    readonly property bool open: UiMode.popout === name && onThisScreen

    Behavior on shownH {
        enabled: root.open && Motion.kind !== "instant"
        NumberAnimation {
            duration: Motion.fast
            easing.type: Easing.OutQuad
        }
    }

    // The button's place in the window. The chain is fixed — button -> cluster
    // -> bar strip — and every offset is read so the binding follows a re-layout
    // (the right-hand cluster shifts left as the tray grows).
    readonly property var anchorSpot: {
        const item = root.anchorItem;
        if (!item || !root.strip)
            return Qt.point(0, 0);
        const cluster = item.parent;
        return Qt.point(
            root.strip.x + (cluster ? cluster.x : 0) + item.x,
            root.strip.y + (cluster ? cluster.y : 0) + item.y
        );
    }
    readonly property real anchorLen: root.anchorItem
        ? (root.vertical ? root.anchorItem.height : root.anchorItem.width)
        : 0

    // Where the card sits along the bar. Window coordinates, which are screen
    // coordinates: the bar window covers the whole output.
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

    // Across the bar the card is glued to the strip and overlaps its last row by
    // a pixel, so the two read as one surface instead of a card with a line
    // across the joint.
    readonly property real cardX: root.vertical
        ? (root.edge === "right" ? root.spanW - root.bar + 1 - root.cardW : root.bar - 1)
        : Math.max(8, Math.min(root.cardAlong, root.spanW - root.cardW - 8))
    readonly property real cardY: root.vertical
        ? Math.max(8, Math.min(root.cardAlong, root.spanH - root.shownH - 8))
        : (root.edge === "bottom" ? root.spanH - root.bar + 1 - root.shownH : root.bar - 1)

    onOpenChanged: {
        if (!open) {
            if (UiMode.hoverCard === root.name)
                UiMode.hoverCard = "";
            return;
        }
        adoptSize();
        card.forceActiveFocus();
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
        id: card
        // The final rect of the menu, and the part of the window that is a menu.
        // It does not move with the reveal: the clip inside it uncovers the card.
        x: Math.round(root.cardX)
        y: Math.round(root.cardY)
        width: root.cardW
        height: root.shownH
        // A closed card is fully laid out but takes no input: while a menu is
        // open the window covers the whole output, and an invisible card must not
        // swallow clicks meant for the menu that is actually open.
        enabled: root.open
        focus: true
        Keys.onEscapePressed: UiMode.closeMenus()

        // Keeps a hover-opened menu open while the pointer is on the card.
        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    UiMode.hoverCard = root.name;
                else if (UiMode.hoverCard === root.name)
                    UiMode.hoverCard = "";
            }
        }

        // Swallow clicks on the card itself so they never reach the bar window's
        // click-away area underneath.
        MouseArea {
            z: -1
            anchors.fill: parent
            onClicked: {}
        }

        Item {
            id: morph
            // The clip grows out of the bar; the edge that meets the bar stays put.
            width: root.vertical ? Math.round(root.cardW * reveal.value) : root.cardW
            height: root.vertical ? root.shownH : Math.round(root.shownH * reveal.value)
            x: root.vertical ? (root.edge === "right" ? root.cardW - width : 0) : 0
            y: root.vertical ? 0 : (root.edge === "bottom" ? root.shownH - height : 0)
            clip: true

            // Frosted material, inside the clip so it is only there where the
            // card is, and aligned to the screen so it continues the bar's. The
            // clip moves while the card reveals, so the offset follows it.
            Glass {
                anchors.fill: parent
                visible: Theme.glass
                screen: root.screen
                regionX: Math.round(root.cardX) + morph.x
                regionY: Math.round(root.cardY) + morph.y
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
