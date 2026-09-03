import QtQuick
import "../widgets"
import "../../services"

BarButton {
    popoutName: "audio"
    onWheeled: steps => Audio.nudge(steps * 0.05)
    onRightClicked: Audio.toggleMute()
    onMiddleClicked: if (Media.player)
        Media.player.togglePlaying()
    BarText {
        text: Audio.muted ? "" : (Audio.volume < 0.33 ? "" : (Audio.volume < 0.66 ? "" : ""))
        icon: true
        px: 13
        color: Audio.muted ? Theme.critical : Theme.fg
    }
}
