import QtQuick
import "../widgets"
import "../../services"

BarButton {
    mark: true
    drawer: true
    implicitWidth: 32
    active: ShellState.sidebarOpen
    BarText {
        text: "単"
        role: "seal"
    }
}
