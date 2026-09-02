import QtQuick
import Quickshell
import "../../services"

BarButton {
    visible: Battery.ready
    popoutName: "battery"
    BarText {
        text: Battery.charging ? "󰂄" : "󰁹"
        icon: true
        px: 13
        color: Battery.percent <= 15 ? Theme.critical : (Battery.percent <= 30 ? Theme.warning : (Battery.percent >= 70 ? Theme.good : Theme.fg))
    }
    BarText {
        text: `${Battery.percent}`
        px: 12
        color: Battery.percent <= 15 ? Theme.critical : Theme.fg
    }
}
