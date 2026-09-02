import QtQuick
import Quickshell
import "../../services"

BarButton {
    popoutName: "clock"
    onRightClicked: Time.cycle()
    BarText {
        text: Time.time
        px: Theme.fontPx
    }
}
