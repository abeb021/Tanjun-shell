import QtQuick
import "../widgets"
import "../../services"

BarButton {
    mark: true
    implicitWidth: 32
    active: ShellState.sidebarOpen
    onClicked: ShellState.toggleSidebar()
    BarText {
        text: "単"
        role: "seal"
    }
}
