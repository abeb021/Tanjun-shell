import QtQuick
import "../widgets"
import "../../services"

BarButton {
    mark: true
    drawer: true
    implicitWidth: 32
    active: UiMode.sidebarOpen

    // The distro mark replaces the seal when this system has a known glyph; an
    // unrecognised distro keeps the Tanjun seal.
    BarText {
        visible: Host.distroIcon.length > 0
        text: Host.distroIcon
        icon: true
        px: Theme.typeSeal
        color: Theme.accent
    }
    BarText {
        visible: Host.distroIcon.length === 0
        text: Theme.tan
        role: "seal"
    }
}
