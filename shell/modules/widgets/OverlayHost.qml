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

    default property alias content: body.data

    readonly property bool shown: (open && onThisScreen) || contentOpacity > 0.02

    visible: shown
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

    Variants {
        model: root.dismissOthers && root.open ? Quickshell.screens : []
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: {
                const mine = root.screen ? `${root.screen.name}` : "";
                return root.open && !!modelData && `${modelData.name}` !== mine;
            }
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
                onClicked: ShellState.closeMenus()
            }
        }
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    signal dismissed

    MouseArea {
        anchors.fill: parent
        enabled: root.open && root.onThisScreen
        onClicked: {
            root.dismissed();
            ShellState.closeMenus();
        }
    }

    Item {
        id: body
        anchors.fill: parent
    }
}
