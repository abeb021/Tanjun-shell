import QtQuick
import QtQuick.Effects
import "../../services"

// Frosted material: the wallpaper, decoded small, blurred and washed with the
// surface tint.
//
// The image is aligned to the *screen*, not to the item, so two surfaces made of
// it that touch — the bar and the menu hanging off it — show one continuous
// image instead of two crops meeting at an edge. The wallpaper is decoded at a
// quarter of the screen and blurred there, so the effect costs a fraction of a
// full-size blur and the upscale is hidden by the blur itself.
Item {
    id: root

    // Where this surface sits on its output, in screen coordinates.
    property real regionX: 0
    property real regionY: 0
    property var screen: null
    property color tint: Theme.bg
    property real alpha: Theme.glassAlpha

    readonly property real screenW: root.screen ? root.screen.width : 1
    readonly property real screenH: root.screen ? root.screen.height : 1
    readonly property real stageScale: 4
    readonly property bool ready: wall.status === Image.Ready

    clip: true

    // The material is always a valid surface: if the wallpaper cannot be read it
    // is simply the surface colour, which is what the shell used before.
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    Item {
        // Quarter-resolution stage, scaled back up to the screen.
        width: Math.max(1, Math.ceil(root.screenW / root.stageScale))
        height: Math.max(1, Math.ceil(root.screenH / root.stageScale))
        x: -root.regionX / root.stageScale
        y: -root.regionY / root.stageScale
        scale: root.stageScale
        transformOrigin: Item.TopLeft

        Image {
            id: wall
            anchors.fill: parent
            source: Theme.wallSource
            sourceSize.width: Math.ceil(root.screenW / root.stageScale)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }

        MultiEffect {
            anchors.fill: wall
            source: wall
            blurEnabled: true
            blurMax: 20
            blur: 1.0
            saturation: -0.15
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.tint
        opacity: root.alpha
    }
}
