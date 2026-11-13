import QtQuick
import Quickshell
import "../widgets"
import "../../services"

Item {
    id: root

    property string screenName: ""
    property bool vertical: false

    readonly property var deskModel: ScriptModel {
        objectProp: "id"
        values: {
            const occupied = Compositor.occupied;
            const focused = Compositor.focusedWorkspaceId;
            const active = Compositor.activeIds;
            return Compositor.deskList();
        }
    }

    implicitWidth: vertical ? col.implicitWidth : row.implicitWidth
    implicitHeight: vertical ? col.implicitHeight : row.implicitHeight

    WheelHandler {
        onWheel: event => {
            Compositor.cycleWorkspace(event.angleDelta.y > 0 ? 1 : -1);
            event.accepted = true;
        }
    }

    Row {
        id: row
        visible: !root.vertical
        spacing: 2

        Repeater {
            model: root.deskModel
            delegate: WorkspaceBtn {
                screenName: root.screenName
            }
        }
    }

    Column {
        id: col
        visible: root.vertical
        width: root.width
        spacing: 2

        Repeater {
            model: root.deskModel
            delegate: WorkspaceBtn {
                vertical: true
                screenName: root.screenName
                width: root.width
            }
        }
    }
}
