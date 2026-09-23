import QtQuick
import "../../services"

Rectangle {
    id: root

    property bool active: false
    property bool danger: false

    radius: Theme.radius
    color: active ? Theme.hot : (danger ? Theme.wash(Theme.critical, 0.06) : "transparent")
    border.width: Theme.chipBorder
    border.color: active ? Theme.accent : (danger ? Theme.wash(Theme.critical, 0.5) : Theme.hairline)
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
}
