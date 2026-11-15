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
    // Stay mapped instead of unmapping when hidden.
    //
    // A layer surface that maps and unmaps is animated by the compositor, and
    // those animations are per-compositor config the shell does not own, so the
    // shell's own motion would be doubled. Keeping the surface alive means there
    // is no open/close for the compositor to animate. While hidden it drops its
    // input region, so it cannot swallow clicks.
    property bool keepMapped: false

    default property alias content: body.data

    readonly property bool shown: (open && onThisScreen) || contentOpacity > 0.02

    visible: root.keepMapped ? true : root.shown
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: -1
    focusable: true
    // A kept-mapped overlay is input-opaque only while it is shown; everything
    // else would sit on top of the desktop with an empty region.
    mask: root.shown ? barMask : emptyMask

    WlrLayershell.namespace: root.layerName
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: keys.mode

    KeyPrime {
        id: keys
        open: root.open && root.onThisScreen && root.grabKeys
        holdExclusive: root.holdExclusive
        // A click into an open overlay must reach its own controls, not only
        // become the focus assignment. A timer (not a call, and not a click
        // handler) re-asserts it, because the shortcut context is only right
        // once the surface is actually up.
        focusDelay: 125
        focusTarget: root.grabTarget
    }

    // A full-screen overlay punches the bar out of its input mask so the bar
    // stays clickable underneath. (Bar menus are not overlays: they live in the
    // bar's own window, which owns its input region.)
    Region {
        id: barMask
        item: barHole
        intersection: Intersection.Xor
    }

    // A zero-sized region: nothing takes input.
    Region {
        id: emptyMask
    }

    // The bar's rect in this surface, as one explicit geometry.
    //
    // Anchors cannot express this: they are only assignable, so a binding that
    // resolves to `undefined` for the current edge leaves the *previous* anchor
    // in place, and after the bar moves the item keeps a mix of edges (left and
    // top and bottom at once). That rectangle belongs to no bar, the XOR below
    // stops excluding the drawer, and the sidebar goes dead to clicks until a
    // reload rebuilds it. Explicit x/y/width/height is always the current edge.
    readonly property int barHoleThickness: Theme.barThickness
    readonly property real barHoleX: Theme.barEdge === "right" ? Math.max(0, root.width - barHoleThickness) : 0
    readonly property real barHoleY: Theme.barEdge === "bottom" ? Math.max(0, root.height - barHoleThickness) : 0
    readonly property real barHoleW: Theme.barVertical ? barHoleThickness : root.width
    readonly property real barHoleH: Theme.barVertical ? root.height : barHoleThickness

    Item {
        id: barHole
        x: root.barHoleX
        y: root.barHoleY
        width: root.barHoleW
        height: root.barHoleH
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
            if (`${s.name}` === mine)
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
            WlrLayershell.layer: WlrLayer.Overlay
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
            // Same explicit rect as the host's punch-out, for the same reason:
            // an anchor left over from the previous edge would punch the wrong
            // strip out and leave this backdrop swallowing the sidebar.
            Item {
                id: awayHole
                x: root.barHoleX
                y: root.barHoleY
                width: root.barHoleW
                height: root.barHoleH
            }
            MouseArea {
                anchors.fill: parent
                onClicked: UiMode.closeMenus()
            }
        }
    }

    // Margins only apply to anchored edges, and a layer surface with no anchors
    // is centred on the output. Every overlay is a full-screen surface anchored
    // on four sides.
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

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
            // A press on the panel is not a press away from it. That matters
            // because with OnDemand keyboard focus the press itself is the focus
            // assignment, so the panel never sees it — and the first click used
            // to close the menu it landed on.
            const delegate = body.children.length > 0 ? body.children[0] : null;
            const inside = delegate && delegate.visible
                && delegate.contains(mapToItem(delegate, Qt.point(mouse.x, mouse.y)));
            if (inside) {
                keys.hold();
                return;
            }
            root.dismissed();
            UiMode.closeMenus();
        }
    }

    // Focus hand-over for this panel. `focusField` is the item that should hold
    // the keys (a search box, the drawer); by default it is the item that fills
    // this host (the card), falling back to the panel scope.
    property Item focusField: null
    readonly property Item grabTarget: focusField || contentItem || focusScope

    Item {
        id: focusScope
        anchors.fill: parent
        focus: root.open && root.onThisScreen
    }

    Item {
        id: body
        anchors.fill: parent
    }
}
