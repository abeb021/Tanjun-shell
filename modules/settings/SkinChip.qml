import QtQuick
import "../widgets"
import "../../services"

Item {
    id: root
    property var pal: ({})
    property bool active: false
    signal clicked

    width: 176
    height: 58

    readonly property color bg: pal.bg || Theme.bg
    readonly property color surface: pal.surface || Theme.surface
    readonly property color fg: pal.fg || Theme.fg
    readonly property color accent: pal.accent || Theme.accent

    Rectangle {
        anchors.fill: parent
        color: root.bg
        border.width: 1
        border.color: root.active || hover.containsMouse ? root.accent : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.2)
        radius: Theme.radius

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            BarText {
                text: pal.label || pal.name || ""
                px: 12
                family: Config.defaultFontUi
                color: root.fg
            }
            Row {
                spacing: 4
                Repeater {
                    model: [root.bg, root.surface, root.fg, root.accent]
                    Rectangle {
                        required property var modelData
                        width: 18
                        height: 18
                        color: modelData
                        border.width: 1
                        border.color: root.fg
                        radius: Theme.radius
                    }
                }
            }
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
