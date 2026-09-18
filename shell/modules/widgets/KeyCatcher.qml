import QtQuick
import "../../services"

Item {
    id: root

    property int count: 0
    property int currentIndex: 0

    signal pick(int index)
    signal cancel

    Keys.priority: Keys.BeforeItem
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.cancel();
            event.accepted = true;
            return;
        }
        const n = root.count;
        if (n < 1)
            return;
        if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
            root.currentIndex = (root.currentIndex + 1) % n;
            event.accepted = true;
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
            root.currentIndex = (root.currentIndex - 1 + n) % n;
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.pick(root.currentIndex);
            event.accepted = true;
        }
    }
}
