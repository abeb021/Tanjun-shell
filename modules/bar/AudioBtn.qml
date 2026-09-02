import QtQuick
import Quickshell
import "../../services"

BarButton {
    popoutName: "audio"
    onWheeled: steps => Audio.nudge(steps * 0.05)
    onRightClicked: Audio.toggleMute()
    BarText {
        text: Audio.muted ? "" : (Audio.volume < 0.33 ? "" : (Audio.volume < 0.66 ? "" : ""))
        icon: true
        px: 13
        color: Audio.muted ? Theme.critical : Theme.fg
    }
}
