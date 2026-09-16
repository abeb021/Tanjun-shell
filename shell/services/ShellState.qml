pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string popout: ""
    property var popoutAnchor: null
    property var trayItem: null
    property string popoutScreen: ""
    property string sidebarScreen: ""

    function screenNameOf(item) {
        try {
            const win = item && item.QsWindow ? item.QsWindow.window : null;
            if (win && win.screen && win.screen.name)
                return `${win.screen.name}`;
        } catch (e) {}
        return Compositor.focusedOutput;
    }

    property bool launcherOpen: false
    property bool clipboardOpen: false
    property bool overviewOpen: false
    property bool sidebarOpen: false
    property bool settingsOpen: false
    property bool dnd: false

    property bool launcherReady: false
    property bool clipboardReady: false
    property bool overviewReady: false
    property bool settingsReady: false

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
        settingsOpen = false;
        if (name !== "tray")
            trayItem = null;
        popoutAnchor = anchor ?? popoutAnchor;
        popoutScreen = screenNameOf(anchor);
        popout = name;
    }

    function openTray(item, anchor) {
        if (popout === "tray" && trayItem === item) {
            closePopout();
            return;
        }
        trayItem = item;
        launcherOpen = false;
        clipboardOpen = false;
        overviewOpen = false;
        sidebarOpen = false;
        settingsOpen = false;
        popoutAnchor = anchor ?? popoutAnchor;
        popoutScreen = screenNameOf(anchor);
        popout = "tray";
    }

    function closePopout() {
        popout = "";
        popoutAnchor = null;
        popoutScreen = "";
        trayItem = null;
    }

    function closeMenus() {
        closePopout();
        launcherOpen = false;
        clipboardOpen = false;
        overviewOpen = false;
        sidebarOpen = false;
        settingsOpen = false;
        sidebarScreen = "";
    }

    function toggleSidebar() {
        closePopout();
        launcherOpen = false;
        clipboardOpen = false;
        overviewOpen = false;
        settingsOpen = false;
        sidebarOpen = !sidebarOpen;
    }

    function toggleLauncher() {
        closePopout();
        clipboardOpen = false;
        overviewOpen = false;
        sidebarOpen = false;
        settingsOpen = false;
        if (!launcherOpen)
            launcherReady = true;
        launcherOpen = !launcherOpen;
    }

    function toggleClipboard() {
        closePopout();
        launcherOpen = false;
        overviewOpen = false;
        sidebarOpen = false;
        settingsOpen = false;
        if (!clipboardOpen)
            clipboardReady = true;
        clipboardOpen = !clipboardOpen;
    }

    function toggleSettings() {
        closePopout();
        launcherOpen = false;
        clipboardOpen = false;
        overviewOpen = false;
        sidebarOpen = false;
        if (!settingsOpen)
            settingsReady = true;
        settingsOpen = !settingsOpen;
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
        settingsOpen = false;
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
