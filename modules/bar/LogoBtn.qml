import QtQuick
import "../widgets"
import "../../services"

BarButton {
    implicitWidth: 28
    active: ShellState.sidebarOpen
    onClicked: ShellState.toggleSidebar()
    BarText {
        text: "単"
        family: Theme.fontJp
        px: 16
        color: Theme.accent
    }
}
