import QtQuick
import Quickshell
import "../../services"

BarButton {
    popoutName: "clock"
    BarText {
        text: Time.time
        px: Theme.fontPx
    }
}
