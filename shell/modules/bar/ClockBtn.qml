import QtQuick
import "../widgets"
import "../../services"

BarButton {
    popoutName: "clock"
    property bool compact: false
    onRightClicked: Time.cycle()
    onMiddleClicked: Time.tzIndex = 0
    onWheeled: steps => Time.cycle(steps)
    BarText {
        text: compact ? Time.time.replace(/\s?[AP]M$/i, "") : Time.time
        px: compact ? 10 : Theme.fontPx
    }
}
