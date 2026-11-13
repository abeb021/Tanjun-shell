import QtQuick
import "../widgets"
import "../../services"

BarButton {
    id: wsBtn

    required property var modelData
    property string screenName: ""
    property bool vertical: false

    property int wsId: Number(modelData.id) || 0
    property bool occupied: {
        const occ = Compositor.occupied || {};
        return !!(occ[wsBtn.wsId] || occ[`${wsBtn.wsId}`]);
    }
    property int hereId: {
        const map = Compositor.activeByOutput || {};
        return Number(map[screenName]) || 0;
    }

    active: hereId > 0 && hereId === wsId
    implicitWidth: vertical ? Theme.barThickness : 22
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
