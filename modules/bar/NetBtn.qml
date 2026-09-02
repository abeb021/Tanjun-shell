import QtQuick
import Quickshell
import "../../services"

BarButton {
    popoutName: "network"
    BarText {
        text: Net.connected ? "󰤨" : "󰤭"
        icon: true
        px: 13
        color: Net.connected ? Theme.fg : Theme.fgSub
    }
}
