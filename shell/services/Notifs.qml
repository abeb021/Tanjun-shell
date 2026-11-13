pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property int unread: 0
    readonly property var list: server.trackedNotifications
    readonly property int keep: 24
    // Every tracked notification, as an array: the model itself has no length.
    readonly property var items: root.list ? root.list.values : []
    readonly property int count: root.items.length
    // Ids already shown in the menu. Their toasts must not pop back after the
    // menu closes — the menu is where they were read.
    property var seenIds: ({})
    readonly property var toasts: {
        const out = [];
        const rows = root.items;
        const seen = root.seenIds;
        for (let i = 0; i < rows.length; i++) {
            const n = rows[i];
            if (n && !seen[n.id])
                out.push(n);
        }
        return out;
    }

    function markSeen() {
        const rows = root.items;
        const m = {};
        for (let i = 0; i < rows.length; i++) {
            if (rows[i])
                m[rows[i].id] = true;
        }
        seenIds = m;
        unread = 0;
    }

    function trim() {
        const items = server.trackedNotifications.values;
        if (!items)
            return;
        const snap = [...items];
        const extra = snap.length - keep;
        if (extra <= 0)
            return;
        for (let i = 0; i < extra; i++) {
            if (snap[i])
                snap[i].tracked = false;
        }
    }

    NotificationServer {
        id: server
        actionsSupported: true
        actionIconsSupported: true
        bodyMarkupSupported: true
        imageSupported: false
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true;
            if (!UiMode.dnd)
                root.unread += 1;
            Qt.callLater(root.trim);
        }
    }

    Connections {
        target: UiMode
        function onPopoutChanged() {
            if (UiMode.popout === "notify")
                root.markSeen();
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
