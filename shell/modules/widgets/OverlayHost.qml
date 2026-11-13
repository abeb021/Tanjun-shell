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
    //
    // A layer surface that maps and unmaps is animated by the compositor, and
    // those animations are per-compositor config the shell does not own: on
    // Hyprland a popup would pick up `layersOut popin` and close like a window.
    // Keeping the surface alive means the compositor has no open/close to
    // animate, so the motion is entirely the shell's — on any compositor.
    property bool keepMapped: false

    default property alias content: body.data

    readonly property bool shown: (open && onThisScreen) || contentOpacity > 0.02

    visible: keepMapped ? true : shown
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: -1
    focusable: true
    mask: Region {
        item: barHole
        intersection: Intersection.Xor
    }

    WlrLayershell.namespace: root.layerName
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: keys.mode

    KeyPrime {
        id: keys
        open: root.open && root.onThisScreen && root.grabKeys
        holdExclusive: root.holdExclusive
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
            if (s && `${s.name}` !== mine)
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
            MouseArea {
                anchors.fill: parent
                onClicked: UiMode.closeMenus()
            }
        }
    }

    anchors {
        top: true
        left: true
        right: !root.keepMapped
        bottom: !root.keepMapped
    }

    // A collapsed surface still answers the compositor, but costs a pixel instead
    // of a screen-sized buffer while the popup is closed.
    implicitWidth: root.keepMapped ? (root.shown ? (root.screen ? root.screen.width : 1) : 1) : 0
    implicitHeight: root.keepMapped ? (root.shown ? (root.screen ? root.screen.height : 1) : 1) : 0

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
