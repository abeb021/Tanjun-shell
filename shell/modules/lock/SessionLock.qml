import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

Scope {
    WlSessionLock {
        locked: Lock.locked

        WlSessionLockSurface {
            color: Theme.bg
            LockSurface {
                anchors.fill: parent
            }
        }
    }
}
