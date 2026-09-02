import QtQuick
import Quickshell
import "../../services"

BarButton {
    popoutName: "menu"
    implicitWidth: 28
    BarText {
        text: "単"
        family: Theme.fontJp
        px: 16
        color: Theme.accent
    }
}
