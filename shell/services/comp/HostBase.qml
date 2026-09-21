import QtQuick
import Quickshell

Item {
    id: root

    property bool live: false
    property bool hasGamma: false
    property bool grabFocus: false
    property bool idleInhibited: false
    property bool overviewOpen: false
    property string screenNote: ""
    property var monitorQuery: ["true"]
    property var gammaQuery: ["true"]
    property string focusedOutput: ""
    property int focusedWorkspaceId: 0
    property var occupied: ({})
    property var activeIds: []
    property var activeByOutput: ({})
    property var windows: []
    property string layoutName: ""

    signal applied
    signal overviewWanted

    function activateWorkspace(id) {}
    function moveToWorkspace(id) {}
    function cycleWorkspace(delta) {}
    function exitSession() {}
    function toggleOverview() {
        overviewWanted();
    }
    function refreshWindows() {}
    function setDpms(on) {}
    function focusWindow(addr) {}
    function cycleLayout(keyboard) {}
    function activeWorkspaceOn(screen) {
        const name = screen && screen.name ? `${screen.name}` : "";
        const n = Number((activeByOutput || {})[name]) || 0;
        return n || focusedWorkspaceId;
    }
    function parseMonitors(text) {
        return null;
    }
    function applyMonitor(row) {}
    function persistMonitors(rows) {}
    function setGamma(n) {}
    function identityGamma() {}
    function readGamma(text) {
        return 0;
    }
}
