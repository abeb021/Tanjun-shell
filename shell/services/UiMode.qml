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
    property bool launcherCatchAway: true

    readonly property string kind: {
        if (settingsOpen)
            return "settings";
        if (launcherOpen)
            return "launcher";
        if (clipboardOpen)
            return "clipboard";
        if (overviewOpen)
            return "overview";
        if (sidebarOpen)
            return "sidebar";
        if (popout.length)
            return popout;
        return "";
    }

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
    property bool wallsOpen: false
    property string wallFolder: ""

    onSidebarOpenChanged: if (!sidebarOpen)
        wallsOpen = false

    property bool launcherReady: false
    property bool clipboardReady: false
    property bool overviewReady: false
    property bool settingsReady: false
    property string overviewPick: ""
    property int overviewCount: 0

    function togglePopout(name, anchor) {
        if (popout === name) {
            closeMenus();
            return;
        }
        launcherOpen = false;
        clipboardOpen = false;
        overviewOpen = false;
        sidebarOpen = false;
        settingsOpen = false;
        dropTimer.restart();
        if (name !== "tray")
            trayItem = null;
        popoutAnchor = anchor ?? popoutAnchor;
        popoutScreen = screenNameOf(anchor);
        if (!popoutScreen.length)
            popoutScreen = Compositor.focusedOutput;
        popout = name;
    }

    function openTray(item, anchor) {
        if (popout === "tray" && trayItem === item) {
            closeMenus();
            return;
        }
        trayItem = item;
        launcherOpen = false;
        clipboardOpen = false;
        overviewOpen = false;
        sidebarOpen = false;
        settingsOpen = false;
        dropTimer.restart();
        popoutAnchor = anchor ?? popoutAnchor;
        popoutScreen = screenNameOf(anchor);
        if (!popoutScreen.length)
            popoutScreen = Compositor.focusedOutput;
        popout = "tray";
    }

    function closePopout() {
        popout = "";
        popoutAnchor = null;
        popoutScreen = "";
        trayItem = null;
    }

    function closeMenus() {
        popout = "";
        popoutAnchor = null;
        popoutScreen = "";
        trayItem = null;
        launcherOpen = false;
        clipboardOpen = false;
        overviewOpen = false;
        sidebarOpen = false;
        settingsOpen = false;
        sidebarScreen = "";
        overviewPick = "";
        overviewCount = 0;
        wallsOpen = false;
        dropTimer.restart();
    }

    function toggleSidebar() {
        if (sidebarOpen) {
            closeMenus();
            return;
        }
        closePopout();
        launcherOpen = false;
        clipboardOpen = false;
        overviewOpen = false;
        settingsOpen = false;
        dropTimer.restart();
        sidebarScreen = Compositor.focusedOutput;
        sidebarOpen = true;
    }

    function toggleLauncher() {
        if (launcherOpen) {
            closeMenus();
            return;
        }
        closePopout();
        clipboardOpen = false;
        overviewOpen = false;
        sidebarOpen = false;
        settingsOpen = false;
        clipboardReady = false;
        overviewReady = false;
        settingsReady = false;
        launcherReady = true;
        launcherOpen = true;
    }

    function toggleClipboard() {
        if (clipboardOpen) {
            closeMenus();
            return;
        }
        closePopout();
        launcherOpen = false;
        overviewOpen = false;
        sidebarOpen = false;
        settingsOpen = false;
        overviewReady = false;
        settingsReady = false;
        clipboardReady = true;
        clipboardOpen = true;
    }

    function toggleSettings() {
        if (settingsOpen) {
            closeMenus();
            return;
        }
        closePopout();
        launcherOpen = false;
        clipboardOpen = false;
        overviewOpen = false;
        sidebarOpen = false;
        clipboardReady = false;
        overviewReady = false;
        settingsReady = true;
        if (!SettingsNav.pageOk(SettingsNav.page))
            SettingsNav.page = "system";
        settingsOpen = true;
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
        clipboardReady = false;
        settingsReady = false;
        overviewPick = "";
        overviewCount = 0;
        overviewReady = true;
        overviewOpen = true;
    }

    function confirmOverview() {
        if (!overviewOpen)
            return;
        overviewCommit++;
    }

    function openWalls() {
        if (!sidebarOpen)
            toggleSidebar();
        if (!wallFolder.length)
            wallFolder = Theme.wallDir;
        wallsOpen = true;
    }

    function setWallFolder(path) {
        let p = `${path || ""}`;
        if (p.startsWith("file://")) {
            p = p.slice(7);
            if (p.startsWith("localhost"))
                p = p.slice("localhost".length);
            try {
                p = decodeURIComponent(p);
            } catch (e) {}
        }
        if (p.startsWith("~/"))
            p = `${Quickshell.env("HOME") || ""}${p.slice(1)}`;
        wallFolder = p;
    }

    function pickWall(path) {
        wallsOpen = false;
        Theme.setWallpaper(path);
    }

    Timer {
        id: dropTimer
        interval: Motion.panel
        repeat: false
        onTriggered: {
            if (!root.settingsOpen)
                root.settingsReady = false;
            if (!root.overviewOpen)
                root.overviewReady = false;
            if (!root.clipboardOpen)
                root.clipboardReady = false;
        }
    }
}
