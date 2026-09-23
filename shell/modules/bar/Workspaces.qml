import QtQuick
import Quickshell
import "../widgets"
import "../../services"

Row {
    id: root
    spacing: 2
    property string screenName: ""

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
            property int wsId: Number(modelData.id) || 0
            property bool occupied: {
                const occ = Compositor.occupied || {};
                return !!(occ[wsBtn.wsId] || occ[`${wsBtn.wsId}`]);
            }
            property int hereId: {
                const map = Compositor.activeByOutput || {};
                return Number(map[root.screenName]) || 0;
            }
            active: hereId > 0 && hereId === wsId
            implicitWidth: 22
            onClicked: Compositor.activateWorkspace(wsId)
            onRightClicked: Compositor.moveToWorkspace(wsId)
            BarText {
                text: `${wsBtn.wsId}`
                px: 11
                color: wsBtn.active ? Theme.accent : (wsBtn.occupied ? Theme.fg : Theme.fgSub)
                Behavior on color {
                    enabled: Motion.ready
                    ColorAnimation {
                        duration: Motion.fast
                    }
                }
            }
        }
    }
}
