import QtQuick
import "../widgets"
import "../../services"

BarButton {
    mark: true
    drawer: true
    implicitWidth: 32
    active: UiMode.sidebarOpen
    BarText {
        text: Theme.tan
        role: "seal"
    }
}
