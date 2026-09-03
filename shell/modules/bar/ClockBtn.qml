import QtQuick
import "../widgets"
import "../../services"

BarButton {
    popoutName: "clock"
    onRightClicked: Time.cycle()
    onMiddleClicked: Time.tzIndex = 0
    onWheeled: steps => Time.cycle(steps)
    BarText {
        text: Time.time
        px: Theme.fontPx
    }
}
