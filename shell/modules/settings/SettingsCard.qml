import QtQuick
import "../widgets"
import "../../services"

Item {
    id: root

    default property alias content: body.data
    property bool open: false

    opacity: open ? 1 : 0
    visible: opacity > 0.01
    scale: open ? 1 : Motion.panelFrom
    transform: Slide {
        open: root.open
        fromY: Motion.panelY
        duration: Motion.panel
    }

    Behavior on opacity {
        enabled: Motion.ready
        NumberAnimation {
            duration: Motion.panel
            easing.type: open ? Motion.enterEase : Motion.easeIn
        }
    }
    Behavior on scale {
        enabled: Motion.ready
        NumberAnimation {
            duration: Motion.panel
            easing.type: open ? Motion.enterEase : Motion.easeIn
        }
    }

    Face {
        job: "plane"
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Item {
            id: body
            anchors.fill: parent
            anchors.margins: Theme.cardPad
            clip: true
        }
    }
}
