import QtQuick
import "../widgets"
import "../../services"

BarButton {
    id: root
    visible: Battery.ready
    popoutName: "battery"
    property bool compact: false
    onWheeled: steps => Backlight.nudge(steps * 5)
    BarText {
        text: Battery.icon
        icon: true
        px: 13
        color: Battery.percent <= 15 ? Theme.critical : (Battery.percent <= 30 ? Theme.warning : (Battery.percent >= 70 ? Theme.good : Theme.fg))
    }
    BarText {
        visible: !root.compact
        text: `${Battery.percent}`
        px: 12
        color: Battery.percent <= 15 ? Theme.critical : Theme.fg
    }
}
