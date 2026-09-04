import QtQuick
import Quickshell
import "../widgets"
import "../../services"

Row {
    id: root
    spacing: 2

    readonly property var items: {
        const occupied = Compositor.occupied || {};
        const out = [];
        for (let i = 1; i <= 10; i++) {
            const ws = occupied[i] ? true : occupied[`${i}`] ? true : false;
            if (i <= 3 || ws)
                out.push({
                    id: i,
                    occupied: ws
                });
        }
        return out;
    }

    WheelHandler {
        onWheel: event => {
            Compositor.cycleWorkspace(event.angleDelta.y > 0 ? 1 : -1);
            event.accepted = true;
        }
    }

    Repeater {
        model: root.items
        delegate: BarButton {
            id: wsBtn
            required property var modelData
            property int wsId: modelData.id
            property bool occupied: modelData.occupied
            active: Compositor.focusedWorkspaceId === wsId
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
