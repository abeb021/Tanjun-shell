pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Singleton {
    id: root

    readonly property bool watching: true
    property string sleepCmd: ""
    property string pendingKind: ""
    property bool logindBlock: false

    readonly property bool restBlocked: Compositor.idleInhibited || logindBlock

    function dim() {
        Quickshell.execDetached(["brightnessctl", "-s", "set", "30%"]);
        Quickshell.execDetached(["brightnessctl", "-sd", "rgb:kbd_backlight", "set", "0"]);
    }

    function undim() {
        Quickshell.execDetached(["brightnessctl", "-r"]);
        Quickshell.execDetached(["brightnessctl", "-rd", "rgb:kbd_backlight"]);
    }

    function sleepNow(cmd) {
        if (restBlocked)
            return;
        Lock.request();
        sleepCmd = cmd;
        sleepWait.restart();
    }

    function goIdle(kind) {
        pendingKind = kind;
        if (Compositor.idleInhibited)
            return;
        inhibitProc.running = false;
        Qt.callLater(() => {
            inhibitProc.running = true;
        });
    }

    function runPending() {
        const kind = pendingKind;
        pendingKind = "";
        if (restBlocked || !kind.length)
            return;
        if (kind === "dim")
            root.dim();
        else if (kind === "lock")
            Lock.request();
        else if (kind === "dpms")
            Compositor.setDpms(false);
        else if (kind === "suspend" || kind === "hibernate")
            root.sleepNow(kind);
    }

    Timer {
        id: sleepWait
        interval: 400
        repeat: false
        onTriggered: {
            if (root.sleepCmd.length)
                Quickshell.execDetached(["systemctl", root.sleepCmd]);
        }
    }

    Process {
        id: inhibitProc
        command: ["python3", `${Quickshell.shellDir}/scripts/tanjun-idle.py`]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                root.logindBlock = text.trim() === "true";
                root.runPending();
            }
        }
    }

    IdleMonitor {
        timeout: 120
        onIsIdleChanged: {
            if (isIdle)
                root.goIdle("dim");
            else
                root.undim();
        }
    }

    IdleMonitor {
        timeout: 300
        onIsIdleChanged: {
            if (isIdle)
                root.goIdle("lock");
        }
    }

    IdleMonitor {
        timeout: 600
        onIsIdleChanged: {
            if (isIdle)
                root.goIdle("dpms");
            else
                Compositor.setDpms(true);
        }
    }

    IdleMonitor {
        timeout: 900
        onIsIdleChanged: {
            if (isIdle)
                root.goIdle("suspend");
        }
    }

    IdleMonitor {
        timeout: 1800
        onIsIdleChanged: {
            if (isIdle)
                root.goIdle("hibernate");
        }
    }
}
