import QtQuick
import "../widgets"
import "../../services"

BarButton {
    id: root
    required property var modelData
    implicitWidth: 22
    active: UiMode.popout === "tray" && UiMode.trayItem === modelData

    onClicked: {
        if (modelData.onlyMenu && modelData.hasMenu) {
            UiMode.openTray(modelData, root);
            return;
        }
        if (UiMode.popout === "tray")
            UiMode.closePopout();
        modelData.activate();
    }
    onRightClicked: {
        if (modelData.hasMenu)
            UiMode.openTray(modelData, root);
        else
            modelData.secondaryActivate();
    }
    onMiddleClicked: modelData.secondaryActivate()
    onWheeled: steps => modelData.scroll(steps * 120, false)

    Image {
        source: root.modelData.icon
        sourceSize.width: 16
        sourceSize.height: 16
        width: 16
        height: 16
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: true
    }
}
