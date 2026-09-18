pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    readonly property bool watching: true

    function dim() {
        Quickshell.execDetached(["brightnessctl", "-s", "set", "30%"]);
        Quickshell.execDetached(["brightnessctl", "-sd", "rgb:kbd_backlight", "set", "0"]);
    }

    function undim() {
        Quickshell.execDetached(["brightnessctl", "-r"]);
        Quickshell.execDetached(["brightnessctl", "-rd", "rgb:kbd_backlight"]);
    }

    IdleMonitor {
        timeout: 120
        onIsIdleChanged: {
            if (isIdle)
                root.dim();
            else
                root.undim();
        }
    }

    IdleMonitor {
        timeout: 300
        onIsIdleChanged: {
            if (isIdle)
                Lock.request();
        }
    }

    IdleMonitor {
        timeout: 600
        onIsIdleChanged: {
            if (isIdle)
                Compositor.setDpms(false);
            else
                Compositor.setDpms(true);
        }
    }

    IdleMonitor {
        timeout: 900
        onIsIdleChanged: {
            if (isIdle)
                Quickshell.execDetached(["systemctl", "suspend"]);
        }
    }

    IdleMonitor {
        timeout: 1800
        onIsIdleChanged: {
            if (isIdle)
                Quickshell.execDetached(["systemctl", "hibernate"]);
        }
    }
}
