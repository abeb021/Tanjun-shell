import QtQuick
import "../../services"

Rectangle {
    id: bar
    property real value: 0
    property color fill: Theme.accent
    property bool interactive: true
    property bool thumb: false
    signal moved(real v)

    height: thumb ? 6 : 4
    radius: Theme.radius
    color: Theme.surface

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
        Rectangle {
            visible: Theme.sliderGlow
            anchors.fill: parent
            anchors.margins: -2
            radius: 4
            color: "transparent"
            border.width: 2
            border.color: Theme.wash(bar.fill, 0.35)
        }
    }

    Rectangle {
        visible: bar.thumb
        width: 10
        height: 10
        radius: Theme.radius
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(bar.width - width, bar.width * Math.max(0, Math.min(1, bar.value)) - width / 2))
        color: bar.fill
        border.width: 1
        border.color: Theme.bg
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
