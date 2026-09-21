import QtQuick
import Quickshell
import "../widgets"
import "../../services"

Row {
    id: root
    spacing: 2
    property var screen: null

    WheelHandler {
        onWheel: event => {
            Compositor.cycleWorkspace(event.angleDelta.y > 0 ? 1 : -1);
            event.accepted = true;
        }
    }

    Repeater {
        model: ScriptModel {
            objectProp: "id"
            values: {
                const occupied = Compositor.occupied;
                const focused = Compositor.focusedWorkspaceId;
                const active = Compositor.activeIds;
                return Compositor.deskList();
            }
        }
        delegate: BarButton {
            id: wsBtn
            required property var modelData
            property int wsId: modelData.id
            property bool occupied: modelData.occupied
            active: Compositor.activeWorkspaceOn(root.screen) === wsId
            implicitWidth: 22
            onClicked: Compositor.activateWorkspace(wsId)
            onRightClicked: Compositor.moveToWorkspace(wsId)
            BarText {
                text: `${wsBtn.wsId}`
                px: 11
                color: wsBtn.active ? Theme.accent : (wsBtn.occupied ? Theme.fg : Theme.fgSub)
            }
        }
    }
}
