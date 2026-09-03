pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string popout: ""
    property var popoutAnchor: null

    property bool launcherOpen: false
    property bool clipboardOpen: false
    property bool overviewOpen: false
    property bool sidebarOpen: false
    property bool dnd: false

    property bool launcherReady: false
    property bool clipboardReady: false
    property bool overviewReady: false

    property string osdKind: ""
    property real osdValue: 0

    function togglePopout(name, anchor) {
        if (popout === name) {
            closePopout();
            return;
        }
        launcherOpen = false;
        clipboardOpen = false;
        overviewOpen = false;
        sidebarOpen = false;
        popoutAnchor = anchor ?? popoutAnchor;
        popout = name;
    }

    function closePopout() {
        popout = "";
        popoutAnchor = null;
    }

    function closeMenus() {
        closePopout();
        launcherOpen = false;
        clipboardOpen = false;
        overviewOpen = false;
        sidebarOpen = false;
    }

    function toggleSidebar() {
        closePopout();
        launcherOpen = false;
        clipboardOpen = false;
        overviewOpen = false;
        sidebarOpen = !sidebarOpen;
    }

    function toggleLauncher() {
        closePopout();
        clipboardOpen = false;
        overviewOpen = false;
        sidebarOpen = false;
        if (!launcherOpen)
            launcherReady = true;
        launcherOpen = !launcherOpen;
    }

    function toggleClipboard() {
        closePopout();
        launcherOpen = false;
        overviewOpen = false;
        sidebarOpen = false;
        if (!clipboardOpen)
            clipboardReady = true;
        clipboardOpen = !clipboardOpen;
    }

    property int overviewNudge: 0
    property int overviewCommit: 0

    function toggleOverview() {
        if (overviewOpen) {
            overviewNudge++;
            return;
        }
        closePopout();
        launcherOpen = false;
        clipboardOpen = false;
        sidebarOpen = false;
        overviewReady = true;
        overviewOpen = true;
    }

    function confirmOverview() {
        if (!overviewOpen)
            return;
        overviewCommit++;
    }

    function showOsd(kind, value) {
        osdKind = kind;
        osdValue = value;
        osdTimer.restart();
    }

    Timer {
        id: osdTimer
        interval: Motion.osdHold
        onTriggered: root.osdKind = ""
    }
}
