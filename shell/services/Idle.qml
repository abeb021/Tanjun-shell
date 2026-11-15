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
        // systemd-inhibit prints the table of holders. This used to go through a
        // Python helper that called `loginctl list-inhibitors` — a verb loginctl
        // does not have — so the check silently never saw a single inhibitor.
        command: ["systemd-inhibit", "--list", "--no-pager"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                root.logindBlock = root.inhibited(text);
                root.runPending();
            }
        }
    }

    // True when any listed inhibitor blocks idle or sleep.
    //
    // Columns are located from the header row rather than by splitting on
    // spaces: WHY is free text, so a reason with spaces in it shifts every
    // column after it when the row is split naively.
    function inhibited(body) {
        const lines = `${body || ""}`.trim().split("\n");
        let whatAt = -1;
        let modeAt = -1;
        let verboseWhat = "";
        for (let i = 0; i < lines.length; i++) {
            const raw = lines[i];
            if (!raw.trim().length)
                continue;
            // Keys and headers are compared on the trimmed line; the table's
            // column offsets are then taken from that same trimmed header so a
            // `line.slice(whatAt, modeAt)` lands on the right characters.
            const line = raw.replace(/\s+$/, "");
            const low = line.trim().toLowerCase();
            const trimAt = line.length - line.trimStart().length;
            // A verbose block (`What:` / `Mode: block`) keeps its own shape, and
            // its keys are indented, so the check runs on the trimmed line.
            if (low.indexOf("what:") === 0) {
                verboseWhat = low.slice(low.indexOf(":") + 1).trim();
                continue;
            }
            if (low.indexOf("mode:") === 0) {
                if (low.slice(low.indexOf(":") + 1).trim().indexOf("block") === 0 && (verboseWhat.indexOf("idle") >= 0 || verboseWhat.indexOf("sleep") >= 0))
                    return true;
                verboseWhat = "";
                continue;
            }
            if (whatAt < 0 && low.indexOf("who") === 0) {
                whatAt = trimAt + low.indexOf("what");
                modeAt = trimAt + low.indexOf("mode");
                continue;
            }
            if (whatAt >= 0 && modeAt >= 0) {
                const what = line.slice(whatAt, modeAt).trim().toLowerCase();
                const mode = line.slice(modeAt).trim().toLowerCase();
                if (mode.indexOf("block") === 0 && (what.indexOf("idle") >= 0 || what.indexOf("sleep") >= 0))
                    return true;
                continue;
            }
            // No header at all (a custom loginctl): fall back to the old shape.
            const parts = line.split(/[\t|]+/).map(s => s.trim()).filter(s => s.length);
            if (parts.length >= 3) {
                const what = parts[parts.length - 3].toLowerCase();
                const mode = parts[parts.length - 1].toLowerCase();
                if (mode === "block" && (what.indexOf("idle") >= 0 || what.indexOf("sleep") >= 0))
                    return true;
            }
        }
        return false;
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
