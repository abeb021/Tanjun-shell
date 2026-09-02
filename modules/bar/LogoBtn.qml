import QtQuick
import Quickshell
import "../../services"

BarButton {
    onClicked: ShellState.toggleSidebar()
    implicitWidth: 28
        BarText {
            text: "単"
            family: Theme.fontJp
            px: 16
            color: Theme.accent
        }
}
