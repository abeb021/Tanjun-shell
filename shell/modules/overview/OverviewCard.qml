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

            ScreencopyView {
                id: preview
                anchors.centerIn: parent
                captureSource: ShellState.overviewOpen && root.client ? root.client.capture : null
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
