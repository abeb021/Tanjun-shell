import QtQuick
import Quickshell
import "../../services"

BarButton {
    onClicked: Layout.cycle()
    BarText {
        text: Layout.keymap
        px: 11
    }
}
