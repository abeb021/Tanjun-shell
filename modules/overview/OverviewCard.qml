import QtQuick
import Quickshell
import Quickshell.Wayland
import "../bar"
import "../../services"

Rectangle {
    id: root

    required property var client
    property bool selected: false

    signal clicked
    signal hovered

    readonly property string winTitle: {
        if (!client)
            return "";
        const t = client.title || "";
        if (t.length)
            return t;
        const o = client.lastIpcObject || {};
        return o.class || "";
    }

    width: 280
    height: 176
    color: Theme.surface
    border.width: 1
    border.color: selected ? Theme.accent : Theme.bg
    radius: Theme.radius

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

            ScreencopyView {
                id: preview
                anchors.centerIn: parent
                captureSource: ShellState.overviewOpen && root.client ? root.client.wayland : null
                live: ShellState.overviewOpen
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
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onEntered: root.hovered()
    }
}
