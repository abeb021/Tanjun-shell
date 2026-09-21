import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

Scope {
    WlSessionLock {
        locked: Lock.locked

        WlSessionLockSurface {
            color: Theme.bg
            Loader {
                anchors.fill: parent
                active: Lock.locked
                source: "file://" + Quickshell.shellDir + "/modules/lock/LockSurface.qml"
            }
        }
    }
}
