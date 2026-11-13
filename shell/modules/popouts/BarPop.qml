import QtQuick
import Quickshell
import "../widgets"
import "../../services"

// A bar menu: a panel hanging off the bar, fading and scaling in from the bar
// side once its content has a final size. The content is loaded while the panel
// is still invisible, so the menu never appears half-built or jumps to its anchor
// after opening.
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
    readonly property string edge: Theme.barEdge
    readonly property bool vertical: edge === "left" || edge === "right"
    // Content is loaded on first open and unloaded after close, while the window
    // stays mapped: the compositor never sees a map/unmap, so it never animates
    // the popup. Keeping the surface costs a pixel of buffer, keeping the QML tree
    // costs tens of megabytes.
    property string source: ""
    property bool everOpen: false
    property int settleTicks: 0
    property int settleTotal: 0
    property int settleLastH: -1
    property int settleLastW: -1

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
    panelHot: morph.revealed

    onOpenChanged: {
        if (open) {
            everOpen = true;
            // The content is recreated on every open, and dynamic lists (audio,
            // network, notifications) refill asynchronously. Measure first, then
            // roll the whole panel out at its final size.
            root.measure();
            root.settleTicks = 0;
            root.settleTotal = 0;
            root.settleLastH = -1;
            root.settleLastW = -1;
            settle.start();
        } else {
            settle.stop();
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
        // Map the anchor through its parent plus the item's own x/y instead of
        // mapToItem(anchor, 0, 0): the latter applies the button's press scale,
        // which shifts the menu by a pixel or two while the button springs back.
        const parentItem = anchorItem.parent;
        const g = parentItem && barWindow
            ? parentItem.mapToItem(barWindow.contentItem, anchorItem.x, anchorItem.y)
            : anchorItem.mapToItem(barWindow ? barWindow.contentItem : null, 0, 0);
        // Use the bar's logical screen origin plus the anchor's position inside
        // the bar. mapToGlobal needs the mapped window position, which is not
        // settled on the very first open; this is correct from the first frame.
        const originX = root.edge === "right" ? scr.width - Theme.barThickness : 0;
        const originY = root.edge === "bottom" ? scr.height - Theme.barThickness : 0;
        const ax = originX + g.x;
        const ay = originY + g.y;
        const bar = Theme.barThickness;
        // Overlap the bar's last row by a pixel: the panel is the bar's own
        // material, so covering the edge (including the chrome rule) makes the
        // two read as one surface instead of a card with a line across it.
        const overlap = 1;
        let x, y;
        if (!root.vertical) {
            x = ax;
            if (align === Item.TopRight)
                x = ax + anchorItem.width - w;
            else if (align === Item.Top)
                x = ax + (anchorItem.width - w) / 2;
            y = root.edge === "top" ? bar - overlap : scr.height - bar - h + overlap;
        } else {
            y = ay + anchorItem.height / 2 - h / 2;
            x = root.edge === "left" ? bar - overlap : scr.width - bar - w + overlap;
        }
        x = Math.max(8, Math.min(x, scr.width - w - 8));
        y = Math.max(8, Math.min(y, scr.height - h - 8));
        root.panelWidth = w;
        root.panelHeight = h;
        root.panelX = Math.round(x);
        root.panelY = Math.round(y);
        root.reportPop();
    }

    function reportPop() {
        UiMode.popGrow = root.edge === "top" ? "down" : (root.edge === "bottom" ? "up" : (root.edge === "left" ? "right" : "left"));
        UiMode.popFromY = root.vertical ? 0 : Motion.popY;
    }

    Connections {
        target: Theme
        function onBarEdgeChanged() {
            root.measure();
        }
    }

    // The bar lays its buttons out after these windows exist; follow the anchor
    // so the closed popup already sits under its button before the first open.
    Connections {
        target: root.anchorItem
        ignoreUnknownSignals: true
        function onXChanged() { root.measure(); }
        function onYChanged() { root.measure(); }
        function onWidthChanged() { root.measure(); }
        function onHeightChanged() { root.measure(); }
    }

    // First open only: the Loader creates the content after `open` flips, and its
    // implicit size settles over a few frames as audio/network data arrives. Stay
    // invisible until the height has been stable for a few ticks, then reveal the
    // whole panel at once.
    Timer {
        id: settle
        interval: 16
        repeat: true
        onTriggered: {
            if (!root.open) {
                stop();
                return;
            }
            root.settleTotal++;
            root.adoptSize();
            const item = pop.item;
            const h = item ? Math.ceil(item.implicitHeight) : 0;
            const w = item ? Math.ceil(item.implicitWidth) : 0;
            if (h > 40 && w > 0 && h === root.settleLastH && w === root.settleLastW) {
                root.settleTicks++;
            } else {
                root.settleLastH = h;
                root.settleLastW = w;
                root.settleTicks = 0;
            }
            if (root.settleTicks >= 4 || root.settleTotal > 30) {
                stop();
                root.adoptSize();
                root.measure();
                morph.revealed = true;
                morph.forceActiveFocus();
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: UiMode.closeMenus()
    }

    // The reveal is the clip again: the panel is fully built at its final size
    // and uncovered from the bar edge by the spring. The difference is that the
    // content is already measured, so nothing grows as it loads.
    SpringProgress {
        id: reveal
        open: morph.revealed
    }

    Item {
        id: morph
        property bool revealed: false
        width: root.vertical ? Math.round(root.cardW * reveal.value) : root.cardW
        height: root.vertical ? root.cardH : Math.round(root.cardH * reveal.value)
        x: root.edge === "right" ? root.cardW - width : 0
        y: root.edge === "bottom" ? root.cardH - height : 0
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
            x: root.edge === "right" ? -(root.cardW - morph.width) : 0
            y: root.edge === "bottom" ? -(root.cardH - morph.height) : 0
            width: root.cardW
            height: root.cardH

            Loader {
                id: pop
                anchors.fill: parent
                active: root.everOpen && (root.open || root.contentOpacity > 0.02)
                source: root.source.length ? Qt.resolvedUrl(root.source) : ""
                onLoaded: root.adoptSize()
            }
        }
    }

    // The content's own height is only known after its first layout pass, which
    // happens after the Loader reports onLoaded. Keep following the item's
    // implicit size instead of freezing the window at its load-time size.
    function adoptSize() {
        if (!root.open)
            return;
        const item = pop.item;
        if (!item)
            return;
        let changed = false;
        const w = Math.ceil(item.implicitWidth);
        const h = Math.ceil(item.implicitHeight);
        if (w > 0 && w !== Math.ceil(root.cardW)) {
            root.cardW = w;
            changed = true;
        }
        if (h > 0 && h !== Math.ceil(root.cardH)) {
            root.cardH = h;
            changed = true;
        }
        if (changed)
            root.measure();
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
