import QtQuick
import "../../services"

Rectangle {
    id: bar
    property real value: 0
    property color fill: Theme.accent
    property bool interactive: true
    signal moved(real v)

    height: 4
    radius: Theme.radius
    color: Theme.bg

    Rectangle {
        width: parent.width * Math.max(0, Math.min(1, bar.value))
        height: parent.height
        color: bar.fill
        Behavior on width {
            enabled: Motion.ready
            NumberAnimation {
                duration: Motion.fast
                easing.type: Motion.easeOut
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: bar.interactive
        onPressed: mouse => bar.moved(mouse.x / width)
        onPositionChanged: mouse => {
            if (pressed)
                bar.moved(mouse.x / width);
        }
    }
}
