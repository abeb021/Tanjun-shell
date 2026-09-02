import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../services"

Row {
    id: root
    spacing: 2

    Repeater {
        model: 10
        delegate: BarButton {
            id: wsBtn
            required property int index
            property int wsId: index + 1
            property var ws: {
                const list = Hyprland.workspaces.values;
                if (!list)
                    return null;
                for (let i = 0; i < list.length; i++) {
                    if (list[i].id === wsId)
                        return list[i];
                }
                return null;
            }
            active: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
            implicitWidth: 22
            onClicked: {
                if (ws)
                    ws.activate();
                else
                    Hyprland.dispatch(`workspace ${wsId}`);
            }
            BarText {
                text: wsBtn.active ? "" : `${wsBtn.wsId}`
                px: 11
                color: wsBtn.active ? Theme.accent : (wsBtn.ws ? Theme.fg : Theme.fgSub)
                icon: wsBtn.active
            }
        }
    }
}
