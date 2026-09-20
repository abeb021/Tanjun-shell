pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string kind: ""
    property real value: 0

    function show(next, amount) {
        kind = next;
        value = amount;
        hold.restart();
    }

    Timer {
        id: hold
        interval: Motion.osdHold
        onTriggered: root.kind = ""
    }
}
