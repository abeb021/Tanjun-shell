import QtQuick
import Quickshell.Wayland
import "../../services"

Item {
    id: root
    visible: false
    width: 0
    height: 0

    required property bool open
    property bool primed: false
    property bool holdExclusive: false
    readonly property int mode: {
        if (!open)
            return WlrKeyboardFocus.None;
        if (holdExclusive || !Compositor.grabFocus)
            return WlrKeyboardFocus.Exclusive;
        return primed ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive;
    }

    onOpenChanged: {
        primed = false;
        if (open)
            primeTimer.restart();
        else
            primeTimer.stop();
    }

    Timer {
        id: primeTimer
        interval: 75
        onTriggered: if (root.open)
            root.primed = true;
    }
}
