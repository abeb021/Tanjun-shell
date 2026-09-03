import QtQuick
import "../widgets"
import "../../services"

BarButton {
    popoutName: "network"
    onRightClicked: Net.toggleWifi()
    BarText {
        text: Net.connected ? "󰤨" : "󰤭"
        icon: true
        px: 13
        color: Net.vpnUp ? Theme.accent : (Net.connected ? Theme.fg : Theme.fgSub)
    }
}
