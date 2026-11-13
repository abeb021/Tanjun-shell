import QtQuick
import "../widgets"
import "../../services"

// A compact clickable control for a popover header.
//
// Unlike a bare glyph it has a body of its own, so it reads as something that
// can be pressed, and the whole chip is the hit area. `active` marks a state
// the user has turned on (DND, muted), which also keeps the control visible
// while the pointer is elsewhere.
Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property bool active: false
    property bool danger: false

    signal clicked

    readonly property bool glyph: root.label.length === 0

    implicitHeight: 22
    implicitWidth: Math.max(26, body.implicitWidth + 14)
    radius: Theme.radius
    color: root.active ? Theme.hot : (hover.hovered ? Theme.hotSoft : Theme.surface)
    border.width: 1
    border.color: root.active || hover.hovered ? Theme.accent : Theme.hairline

    Behavior on color {
        enabled: Motion.ready
        ColorAnimation {
            duration: Motion.fast
        }
    }
    Behavior on border.color {
        enabled: Motion.ready
        ColorAnimation {
            duration: Motion.fast
        }
    }

    BarText {
        id: body
        anchors.centerIn: parent
        text: root.glyph ? root.icon : root.label
        icon: root.glyph
        px: root.glyph ? 12 : 9
        family: root.glyph ? "" : Config.defaultFontUi
        font.letterSpacing: root.glyph ? 0 : 1
        color: root.danger ? Theme.critical : (root.active ? Theme.accent : Theme.fg)
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
