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
    // Size the surface to a fixed panel and pin it where the bar says it goes.
    // The size is the *final* one from the first frame: a mapped layer whose size
    // changes is a rect the WM may re-flow, and on Hyprland a layer that shrinks
    // and grows back stays at the smaller size.
    property bool panelSized: false
    property real panelWidth: 0
    property real panelHeight: 0
    property real panelX: 0
    property real panelY: 0

    default property alias content: body.data

    readonly property bool shown: (open && onThisScreen) || contentOpacity > 0.02
    readonly property bool sized: panelSized && panelWidth > 0 && panelHeight > 0

    visible: keepMapped ? true : shown
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: -1
    focusable: true
    mask: root.panelSized ? panelMask : barMask

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

    Region {
        id: panelMask
        x: 0
        y: 0
        width: root.open ? Math.ceil(root.panelWidth) : 0
        height: root.open ? Math.ceil(root.panelHeight) : 0
    }

    Item {
        id: barHole
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Theme.barHeight
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
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Theme.barHeight
            }
            MouseArea {
                anchors.fill: parent
                onClicked: UiMode.closeMenus()
            }
        }
    }

    // Margins only apply to anchored edges, and a layer surface with no anchors
    // is centred on the output. So the panel is anchored to the top-left and
    // offset by its own rect; the surface then sits exactly where the bar put it.
    // Every other overlay keeps the full-screen surface anchored on four sides.
    anchors {
        top: true
        left: true
        right: !root.keepMapped && !root.panelSized
        bottom: !root.keepMapped && !root.panelSized
    }

    margins.left: root.panelSized ? Math.max(0, Math.round(root.panelX)) : 0
    margins.top: root.panelSized ? Math.max(0, Math.round(root.panelY)) : 0

    implicitWidth: root.panelSized ? (root.sized ? Math.ceil(root.panelWidth) : 1) : (root.keepMapped ? (root.shown ? (root.screen ? root.screen.width : 1) : 1) : 0)
    implicitHeight: root.panelSized ? (root.sized ? Math.ceil(root.panelHeight) : 1) : (root.keepMapped ? (root.shown ? (root.screen ? root.screen.height : 1) : 1) : 0)

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
