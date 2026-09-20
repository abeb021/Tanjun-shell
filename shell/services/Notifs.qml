pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property int unread: 0
    readonly property var list: server.trackedNotifications

    NotificationServer {
        id: server
        actionsSupported: true
        actionIconsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true;
            if (!UiMode.dnd)
                root.unread += 1;
        }
    }

    Connections {
        target: UiMode
        function onPopoutChanged() {
            if (UiMode.popout === "notify")
                root.unread = 0;
        }
    }

    function clear() {
        const items = server.trackedNotifications.values;
        if (!items)
            return;
        for (let i = items.length - 1; i >= 0; i--)
            items[i].dismiss();
        unread = 0;
    }
}
