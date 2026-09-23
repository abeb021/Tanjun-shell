import QtQuick
import Quickshell
import Quickshell.Wayland
import "../widgets"
import "../../services"

Face {
    id: root

    required property var client
    property bool selected: false
    job: "pop"
    lit: selected
    border.color: selected ? Theme.accent : Theme.hairline
    color: selected ? Theme.hot : Theme.surface
    scale: selected ? 1 : 0.98
    Behavior on scale {
        enabled: Motion.ready
        NumberAnimation {
            duration: Motion.fast
            easing.type: Motion.enterEase
        }
    }

    signal clicked
    signal hovered

    readonly property string winTitle: {
        if (!client)
            return "";
        const t = client.title || "";
        if (t.length)
            return t;
        return client.appId || "";
    }

    width: 280
    height: 176

    Column {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 6

        Rectangle {
            width: parent.width
            height: 138
            color: Theme.bg
            clip: true
            radius: Theme.radius
            opacity: root.selected ? 1 : 0.48
            Behavior on opacity {
                enabled: Motion.ready
                NumberAnimation {
                    duration: Motion.fast
                    easing.type: Motion.easeOut
                }
            }

            ScreencopyView {
                id: preview
                anchors.centerIn: parent
                captureSource: UiMode.overviewOpen && root.client ? root.client.capture : null
                live: UiMode.overviewOpen && (root.selected || !preview.hasContent)
                constraintSize.width: parent.width
                constraintSize.height: parent.height
            }

            BarText {
                visible: !preview.hasContent
                anchors.centerIn: parent
                text: "…"
                sub: true
                px: 18
            }
        }

        BarText {
            width: parent.width
            text: root.winTitle
            px: 11
            color: root.selected ? Theme.accent : Theme.fg
            elide: Text.ElideRight
        }
    }

    Rectangle {
        visible: Theme.pip && root.selected
        width: 2
        height: parent.height - 10
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 3
        color: Theme.accent
        z: 12
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onEntered: root.hovered()
    }
}
