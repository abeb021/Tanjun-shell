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
            launcherReady: UiMode.launcherReady
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
