import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

Scope {
    WlSessionLock {
        locked: Lock.locked && !Lock.testHost

        WlSessionLockSurface {
            color: Theme.bg
            Loader {
                anchors.fill: parent
                active: Lock.locked
                sourceComponent: lockFace
            }
        }
    }

    Component {
        id: lockFace
        LockSurface {}
    }
}
