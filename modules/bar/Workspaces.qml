import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../services"

Row {
    id: root
    spacing: 2

    readonly property var items: {
        const occupied = {};
        const list = Hyprland.workspaces.values;
        if (list) {
            for (let i = 0; i < list.length; i++) {
                const id = list[i].id;
                if (id > 0 && id <= 10)
                    occupied[id] = list[i];
            }
        }
        const out = [];
        for (let i = 1; i <= 10; i++) {
            const ws = occupied[i] || null;
            if (i <= 3 || ws)
                out.push({
                    id: i,
                    ws: ws
                });
        }
        return out;
    }

    WheelHandler {
        onWheel: event => {
            Quickshell.execDetached(["hyprctl", "dispatch", "workspace", event.angleDelta.y > 0 ? "e-1" : "e+1"]);
            event.accepted = true;
        }
    }

    Repeater {
        model: root.items
        delegate: BarButton {
            id: wsBtn
            required property var modelData
            property int wsId: modelData.id
            property var ws: modelData.ws
            active: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
            implicitWidth: 22
            onClicked: {
                if (ws)
                    ws.activate();
                else
                    Quickshell.execDetached(["hyprctl", "dispatch", "workspace", `${wsId}`]);
            }
            BarText {
                text: wsBtn.active ? "" : (wsBtn.ws ? `${wsBtn.wsId}` : "")
                px: 11
                color: wsBtn.active ? Theme.accent : (wsBtn.ws ? Theme.fg : Theme.fgSub)
                icon: wsBtn.active || !wsBtn.ws
            }
        }
    }
}
