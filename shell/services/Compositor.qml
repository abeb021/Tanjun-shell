pragma Singleton
import QtQuick
import Quickshell
import "comp"

Singleton {
    id: root

    signal monitorsDirty

    HyprHost {
        id: hypr
        live: !niri.live
        overviewOpen: UiMode.overviewOpen
        onApplied: root.monitorsDirty()
        onOverviewWanted: UiMode.toggleOverview()
    }
    NiriHost {
        id: niri
        live: !!Quickshell.env("NIRI_SOCKET")
        overviewOpen: UiMode.overviewOpen
        onApplied: root.monitorsDirty()
        onOverviewWanted: UiMode.toggleOverview()
    }

    readonly property var host: niri.live ? niri : hypr
    readonly property bool idleInhibited: host.idleInhibited

    readonly property int focusedWorkspaceId: host.focusedWorkspaceId
    readonly property var occupied: host.occupied
    readonly property var activeIds: host.activeIds
    readonly property var windows: host.windows
    readonly property string focusedOutput: host.focusedOutput
    readonly property string layoutName: host.layoutName
    readonly property bool hasGamma: host.hasGamma
    readonly property bool grabFocus: host.grabFocus
    readonly property string screenNote: host.screenNote
    readonly property var monitorQuery: host.monitorQuery
    readonly property var gammaQuery: host.gammaQuery

    function isScreenFocused(screen) {
        const name = focusedOutput;
        if (!name.length || !screen)
            return true;
        return screen.name === name;
    }

    function deskOnMonitor(i) {
        if (i === focusedWorkspaceId)
            return true;
        const active = activeIds || [];
        for (let j = 0; j < active.length; j++) {
            if (Number(active[j]) === i)
                return true;
        }
        return false;
    }

    function deskList() {
        const occ = occupied || {};
        const out = [];
        for (let i = 1; i <= 10; i++) {
            const has = !!(occ[i] || occ[`${i}`]);
            if (i <= 3 || has || deskOnMonitor(i))
                out.push({
                    id: i,
                    occupied: has
                });
        }
        return out;
    }

    function activeWorkspaceOn(screen) {
        return host.activeWorkspaceOn(screen);
    }

    function activateWorkspace(id) {
        host.activateWorkspace(id);
    }
    function moveToWorkspace(id) {
        host.moveToWorkspace(id);
    }
    function cycleWorkspace(delta) {
        host.cycleWorkspace(delta);
    }
    function exitSession() {
        Lock.unlock();
        if (`${Quickshell.env("TANJUN_TEST") || ""}` === "1")
            return;
        const sid = `${Quickshell.env("XDG_SESSION_ID") || ""}`;
        if (sid.length) {
            Quickshell.execDetached(["loginctl", "terminate-session", sid]);
            return;
        }
        host.exitSession();
    }
    function toggleOverview() {
        host.toggleOverview();
    }
    function focusWindow(addr) {
        host.focusWindow(addr);
    }
    function cycleLayout() {
        host.cycleLayout(Config.services.keyboard);
    }
    function parseMonitors(text) {
        return host.parseMonitors(text);
    }
    function applyMonitor(row) {
        host.applyMonitor(row);
    }
    function persistMonitors(rows) {
        host.persistMonitors(rows);
    }
    function setGamma(n) {
        host.setGamma(n);
    }
    function identityGamma() {
        host.identityGamma();
    }
    function readGamma(text) {
        return host.readGamma(text);
    }
    function setDpms(on) {
        host.setDpms(on);
    }
    function refreshWindows() {
        host.refreshWindows();
    }
}
