pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var contract: [
        "live", "hasGamma", "grabFocus", "idleInhibited", "screenNote",
        "focusedOutput", "windows", "activateWorkspace", "persistMonitors",
        "setDpms", "setGamma"
    ]

    function pollObject() {
        return {
            host: Host.ticking,
            vpn: Net.watching,
            weather: Weather.live,
            mixer: Audio.mixerOpen,
            backlightMs: Backlight.pollMs,
            idleInhibited: !!(Compositor.idleInhibited || Idle.logindBlock)
        };
    }

    function pollJson() {
        return JSON.stringify(pollObject());
    }

    function hostCaps() {
        return JSON.stringify({
            hasGamma: Compositor.hasGamma,
            grabFocus: Compositor.grabFocus,
            idleInhibited: Compositor.idleInhibited,
            wallDir: Theme.wallDir,
            screenNote: Compositor.screenNote,
            contract: root.contract,
            pamDir: Lock.pamDir
        });
    }

    function launcherJson() {
        const model = DesktopEntries.applications;
        const raw = model && model.values ? model.values : [];
        const apps = [...raw];
        const sample = [];
        const keys = {};
        let n = 0;
        for (let i = 0; i < apps.length; i++) {
            const a = apps[i];
            if (!a)
                continue;
            const id = `${a.id || a.name || i}`;
            const key = "app:" + i + ":" + id;
            n++;
            keys[key] = true;
            if (sample.length < 12)
                sample.push(a.name || id);
        }
        return JSON.stringify({
            n: n,
            unique: Object.keys(keys).length,
            count: model && model.count !== undefined ? model.count : n,
            sample: sample
        });
    }

    function uiMode() {
        return JSON.stringify({
            kind: UiMode.kind,
            settingsOpen: UiMode.settingsOpen,
            launcherOpen: UiMode.launcherOpen,
            settingsReady: UiMode.settingsReady,
            overviewReady: UiMode.overviewReady,
            overviewPick: UiMode.overviewPick,
            overviewCount: UiMode.overviewCount,
            clipboardReady: UiMode.clipboardReady,
            launcherReady: UiMode.launcherReady,
            sidebarReady: UiMode.sidebarReady,
            launcherCatchAway: UiMode.launcherCatchAway,
            popoutKeep: UiMode.popoutKeep,
            wallsOpen: UiMode.wallsOpen,
            wallFolder: UiMode.wallFolder
        });
    }

    function sidebarJson() {
        return JSON.stringify({
            open: UiMode.sidebarOpen,
            ready: UiMode.sidebarReady,
            x: Math.round(UiMode.sidebarX),
            w: Math.round(UiMode.sidebarW),
            fromX: Math.round(UiMode.sidebarFromX),
            edge: UiMode.sidebarEdge
        });
    }

    function popJson() {
        return JSON.stringify({
            open: !!UiMode.popout.length,
            name: UiMode.popout,
            grow: UiMode.popGrow,
            origin: UiMode.popOrigin,
            scaleX: UiMode.popScaleX,
            fromY: Math.round(UiMode.popFromY)
        });
    }

    function workspaceJson() {
        const occ = Compositor.occupied || {};
        const focused = Compositor.focusedWorkspaceId;
        const activeRaw = Compositor.activeIds || [];
        const occupied = [];
        const active = [];
        const seen = {};
        for (let i = 0; i < activeRaw.length; i++) {
            const n = Number(activeRaw[i]) || 0;
            if (n >= 1 && n <= 10 && !seen[n]) {
                seen[n] = true;
                active.push(n);
            }
        }
        const rows = Compositor.deskList();
        const ids = [];
        for (let i = 0; i < rows.length; i++) {
            ids.push(rows[i].id);
            if (rows[i].occupied)
                occupied.push(rows[i].id);
        }
        const by = Compositor.activeByOutput || {};
        const onOutput = {};
        const keys = Object.keys(by);
        for (let i = 0; i < keys.length; i++)
            onOutput[keys[i]] = Number(by[keys[i]]) || 0;
        return JSON.stringify({
            focused: focused,
            ids: ids,
            occupied: occupied,
            active: active,
            onOutput: onOutput
        });
    }

    function lockJson() {
        return JSON.stringify({
            locked: Lock.locked,
            busy: Lock.busy,
            fail: Lock.fail,
            pamDir: Lock.pamDir,
            leaveSeq: Lock.leaveSeq,
            testHost: Lock.testHost
        });
    }

    function settingsCatalog() {
        const rows = SettingsNav.catalog;
        const out = [];
        for (let i = 0; i < rows.length; i++)
            out.push({ title: rows[i].title, page: rows[i].page || "", sub: rows[i].sub || "" });
        return JSON.stringify(out);
    }
}
