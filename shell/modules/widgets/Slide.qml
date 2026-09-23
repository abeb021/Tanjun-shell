import QtQuick
import "../../services"

Translate {
    id: root

    property bool open: true
    property real fromX: 0
    property real fromY: 0
    property int duration: Motion.pop

    x: open ? 0 : fromX
    y: open ? 0 : fromY

    Behavior on x {
        enabled: Motion.ready
        NumberAnimation {
            duration: root.duration
            easing.type: root.open ? Motion.enterEase : Motion.easeIn
        }
    }
    Behavior on y {
        enabled: Motion.ready
        NumberAnimation {
            duration: root.duration
            easing.type: root.open ? Motion.enterEase : Motion.easeIn
        }
    }
}
