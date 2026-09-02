import QtQuick
import Quickshell
import "../../services"

BarButton {
    onClicked: Layout.cycle()
    onRightClicked: Layout.cycle()
    onWheeled: Layout.cycle()
    BarText {
        text: Layout.keymap
        px: 11
    }
}
