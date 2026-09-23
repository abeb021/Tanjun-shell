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

    readonly property int dimMin: minsOf(Config.idle.dimMin, 2)
    readonly property int lockMin: minsOf(Config.idle.lockMin, 5)
    readonly property int dpmsMin: minsOf(Config.idle.dpmsMin, 10)
    readonly property int sleepMin: minsOf(Config.idle.sleepMin, 15)
    readonly property int hibernateMin: minsOf(Config.idle.hibernateMin, 30)

    readonly property int dimSec: dimMin * 60
    readonly property int lockSec: lockMin * 60
    readonly property int dpmsSec: dpmsMin * 60
    readonly property int sleepSec: sleepMin * 60
    readonly property int hibernateSec: hibernateMin * 60

    function minsOf(raw, fallback) {
        const n = Math.round(Number(raw) || 0);
        return n > 0 ? n : fallback;
    }

    function clampMin(n, lo, hi) {
        const v = Math.round(Number(n) || 0);
        return Math.max(lo, Math.min(hi, v));
    }

    function idleJson() {
        return JSON.stringify({
            dim: dimMin,
            lock: lockMin,
            dpms: dpmsMin,
            sleep: sleepMin,
            hibernate: hibernateMin,
            dimSec: dimSec,
            lockSec: lockSec,
            dpmsSec: dpmsSec,
            sleepSec: sleepSec,
            hibernateSec: hibernateSec
        });
    }

    function applyIdle(raw) {
        let obj = {};
        try {
            obj = JSON.parse(`${raw || ""}`);
        } catch (e) {
            obj = {};
        }
        if (obj.dim !== undefined)
            Config.idle.dimMin = clampMin(obj.dim, 1, 15);
        if (obj.lock !== undefined)
            Config.idle.lockMin = clampMin(obj.lock, 1, 30);
        if (obj.dpms !== undefined)
            Config.idle.dpmsMin = clampMin(obj.dpms, 1, 60);
        if (obj.sleep !== undefined)
            Config.idle.sleepMin = clampMin(obj.sleep, 5, 120);
        if (obj.hibernate !== undefined)
            Config.idle.hibernateMin = clampMin(obj.hibernate, 5, 180);
        Config.writeSparse();
        return idleJson();
    }

    function bump(key, delta) {
        const next = {};
        const cur = {
            dim: dimMin,
            lock: lockMin,
            dpms: dpmsMin,
            sleep: sleepMin,
            hibernate: hibernateMin
        };
        const k = `${key || ""}`;
        if (!(k in cur))
            return idleJson();
        next[k] = cur[k] + Number(delta);
        return applyIdle(JSON.stringify(next));
    }

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
        timeout: Math.max(30, root.dimSec)
        onIsIdleChanged: {
            if (isIdle)
                root.goIdle("dim");
            else
                root.undim();
        }
    }

    IdleMonitor {
        timeout: Math.max(30, root.lockSec)
        onIsIdleChanged: {
            if (isIdle)
                root.goIdle("lock");
        }
    }

    IdleMonitor {
        timeout: Math.max(30, root.dpmsSec)
        onIsIdleChanged: {
            if (isIdle)
                root.goIdle("dpms");
            else
                Compositor.setDpms(true);
        }
    }

    IdleMonitor {
        timeout: Math.max(30, root.sleepSec)
        onIsIdleChanged: {
            if (isIdle)
                root.goIdle("suspend");
        }
    }

    IdleMonitor {
        timeout: Math.max(30, root.hibernateSec)
        onIsIdleChanged: {
            if (isIdle)
                root.goIdle("hibernate");
        }
    }
}
