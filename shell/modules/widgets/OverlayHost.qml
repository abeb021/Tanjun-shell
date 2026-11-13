import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: root

    required property bool open
    property string layerName: "tanjun-overlay"
    property bool onThisScreen: true
    property bool grabKeys: true
    property bool holdExclusive: false
    property bool dismissOthers: false
    property real contentOpacity: 0
    // Stay mapped instead of unmapping when hidden, collapsed to a 1x1 surface.
    // (A panel-sized surface keeps its rect instead and drops its input region
    // while closed.)
    //
    // A layer surface that maps and unmaps is animated by the compositor, and
    // those animations are per-compositor config the shell does not own: on
    // Hyprland a popup would pick up `layersOut popin` and close like a window.
    // Keeping the surface alive means the compositor has no open/close to
    // animate, so the motion is entirely the shell's — on any compositor.
    property bool keepMapped: false
    // A panel-sized surface is pinned to the bar's edge once and spans the bar.
    // Its rect is set up from the bar and then never changes: opening a menu only
    // moves the card *inside* it, in plain item coordinates. Quickshell only
    // commits anchors, margins and size on polish, so a pin that moved would
    // always lag a frame behind the click — a constant pin cannot.
    property bool panelSized: false
    property string panelEdge: "" // "top" | "bottom" | "left" | "right"
    property real panelDepth: 1 // reach of the surface away from the bar
    property real panelInset: 0 // gap between the bar and the surface
    // The card is the only part of a panel-sized surface that takes input. It is
    // zero-sized while the menu is closed, so the surface is transparent to the
    // pointer everywhere else.
    property Item panelHotItem: null

    readonly property bool panelVertical: panelEdge === "left" || panelEdge === "right"

    default property alias content: body.data

    readonly property bool shown: (open && onThisScreen) || contentOpacity > 0.02

    visible: keepMapped ? true : shown
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: -1
    focusable: true
    mask: root.panelSized ? hotMask : barMask

    WlrLayershell.namespace: root.layerName
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: keys.mode

    KeyPrime {
        id: keys
        open: root.open && root.onThisScreen && root.grabKeys
        holdExclusive: root.holdExclusive
    }

    // A full-screen overlay punches the bar out of its input mask so the bar
    // stays clickable underneath. A panel-sized surface *is* the menu, so the
    // whole rect is clickable while open and nothing is while closed: an
    // always-mapped window that kept a full input region would swallow clicks
    // over the desktop even with nothing drawn.
    Region {
        id: barMask
        item: barHole
        intersection: Intersection.Xor
    }

    // A panel-sized surface is input-opaque only where the card is drawn. The
    // region follows the card's animated rect, so the reveal uncovers the input
    // area together with the pixels and nothing outside ever takes a click.
    Region {
        id: hotMask
        item: root.panelHotItem
    }

    Item {
        id: barHole
        anchors.left: (!Theme.barVertical || Theme.barEdge === "left") ? parent.left : undefined
        anchors.right: (!Theme.barVertical || Theme.barEdge === "right") ? parent.right : undefined
        anchors.top: (Theme.barVertical || Theme.barEdge === "top") ? parent.top : undefined
        anchors.bottom: (Theme.barVertical || Theme.barEdge === "bottom") ? parent.bottom : undefined
        width: Theme.barVertical ? Theme.barThickness : parent.width
        height: Theme.barVertical ? parent.height : Theme.barThickness
    }

    readonly property var otherScreens: {
        if (!dismissOthers || !open)
            return [];
        const mine = root.screen ? `${root.screen.name}` : "";
        const all = Quickshell.screens;
        const out = [];
        if (!all)
            return out;
        for (let i = 0; i < all.length; i++) {
            const s = all[i];
            if (!s)
                continue;
            // A full-screen overlay catches clicks away from its panel itself.
            // A panel-sized one only covers the panel, so its own screen needs
            // a backdrop as well; it lives in the bar's layer, under the panel.
            if (!root.panelSized && `${s.name}` === mine)
                continue;
            out.push(s);
        }
        return out;
    }

    Variants {
        model: root.otherScreens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.open && !!modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "tanjun-pop-away"
            // Under the panel-sized popup, which sits in the Overlay layer.
            WlrLayershell.layer: root.panelSized ? WlrLayer.Top : WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            // Keep the bar usable while the backdrop is up.
            mask: Region {
                item: awayHole
                intersection: Intersection.Xor
            }
            Item {
                id: awayHole
                anchors.left: (!Theme.barVertical || Theme.barEdge === "left") ? parent.left : undefined
                anchors.right: (!Theme.barVertical || Theme.barEdge === "right") ? parent.right : undefined
                anchors.top: (Theme.barVertical || Theme.barEdge === "top") ? parent.top : undefined
                anchors.bottom: (Theme.barVertical || Theme.barEdge === "bottom") ? parent.bottom : undefined
                width: Theme.barVertical ? Theme.barThickness : parent.width
                height: Theme.barVertical ? parent.height : Theme.barThickness
            }
            MouseArea {
                anchors.fill: parent
                onClicked: UiMode.closeMenus()
            }
        }
    }

    // Margins only apply to anchored edges, and a layer surface with no anchors
    // is centred on the output. A panel-sized surface is anchored to the bar's
    // edge and stretched along the bar, so its depth is the only axis the shell
    // chooses. Every other overlay keeps the full-screen surface on four sides.
    anchors {
        top: root.panelSized ? root.panelEdge !== "bottom" : true
        bottom: root.panelSized ? root.panelEdge !== "top" : (!root.keepMapped && !root.panelSized)
        left: root.panelSized ? root.panelEdge !== "right" : true
        right: root.panelSized ? root.panelEdge !== "left" : (!root.keepMapped && !root.panelSized)
    }

    // Only the edge the bar is on gets a margin: the stretched axis has none, so
    // coordinates along the bar are screen coordinates and the card can be
    // placed inside the surface without ever touching the pin.
    margins.top: root.panelSized && root.panelEdge === "top" ? Math.max(0, Math.round(root.panelInset)) : 0
    margins.bottom: root.panelSized && root.panelEdge === "bottom" ? Math.max(0, Math.round(root.panelInset)) : 0
    margins.left: root.panelSized && root.panelEdge === "left" ? Math.max(0, Math.round(root.panelInset)) : 0
    margins.right: root.panelSized && root.panelEdge === "right" ? Math.max(0, Math.round(root.panelInset)) : 0

    implicitWidth: root.panelSized ? (root.panelVertical ? Math.max(1, Math.ceil(root.panelDepth)) : 1) : (root.keepMapped ? (root.shown ? (root.screen ? root.screen.width : 1) : 1) : 0)
    implicitHeight: root.panelSized ? (root.panelVertical ? 1 : Math.max(1, Math.ceil(root.panelDepth))) : (root.keepMapped ? (root.shown ? (root.screen ? root.screen.height : 1) : 1) : 0)

    signal dismissed

    function reportCatchAway() {
        if (layerName === "tanjun-launcher")
            UiMode.launcherCatchAway = dismissOthers;
    }

    Component.onCompleted: reportCatchAway()
    onDismissOthersChanged: reportCatchAway()

    MouseArea {
        z: -1
        anchors.fill: parent
        enabled: root.open && root.onThisScreen
        onClicked: {
            root.dismissed();
            UiMode.closeMenus();
        }
    }

    Item {
        id: body
        anchors.fill: parent
    }
}
