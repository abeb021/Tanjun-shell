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
            launcherCatchAway: UiMode.launcherCatchAway,
            wallsOpen: UiMode.wallsOpen,
            wallFolder: UiMode.wallFolder
        });
    }

    function workspaceJson() {
        const occ = Compositor.occupied || {};
        const focused = Compositor.focusedWorkspaceId;
        const occupied = [];
        const ids = [];
        for (let i = 1; i <= 10; i++) {
            const has = !!(occ[i] || occ[`${i}`]);
            if (has)
                occupied.push(i);
            if (i <= 3 || has || i === focused)
                ids.push(i);
        }
        return JSON.stringify({
            focused: focused,
            ids: ids,
            occupied: occupied
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
