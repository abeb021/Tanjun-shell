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
            root.dismissed();
            UiMode.closeMenus();
        }
    }

    Item {
        id: body
        anchors.fill: parent
    }
}
