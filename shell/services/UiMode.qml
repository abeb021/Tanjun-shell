pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string popout: ""
    property string popoutKeep: ""
    property var popoutAnchor: null
    property var trayItem: null
    property string popoutScreen: ""
    property string sidebarScreen: ""
    property bool launcherCatchAway: true
    // Hover-intent menus: hovering a bar button opens its menu after a short
    // delay, and a menu opened that way closes when the pointer leaves both the
    // button and the card. A click leaves hoverPop false, so those menus ignore
    // the pointer and only close on a click away.
    property bool hoverPop: false
    property string hoverCard: ""
    property int hoverButtons: 0
    readonly property int hoverOpenDelay: 420
    readonly property int hoverCloseDelay: 340

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
    property bool sidebarReady: false
    property real sidebarX: 0
    property real sidebarW: 0
    property real sidebarFromX: 0
    property string sidebarEdge: ""
    // bar dragging: a ghost bar follows the pointer, then the bar snaps to the
    // border the pointer is brought to
    property bool barDragging: false
    property string barDragScreen: ""
    property real barDragX: 0
    property real barDragY: 0
    property string barDragEdge: ""
    property string overviewPick: ""
    property int overviewCount: 0

    // The stretch of the bar an open menu covers, in window coordinates, so the
    // bar's inner rule can stop there and the menu reads as the bar opening
    // instead of a card laid over a line. Only one menu is ever open, so a
    // single span is enough.
    property string menuSpanName: ""
    property string menuSpanScreen: ""
    property real menuSpanFrom: -1
    property real menuSpanTo: -1

    function setMenuSpan(name, screen, from, to) {
        menuSpanName = `${name || ""}`;
        menuSpanScreen = `${screen || ""}`;
        menuSpanFrom = from;
        menuSpanTo = to;
    }

    function clearMenuSpan() {
        menuSpanName = "";
        menuSpanScreen = "";
        menuSpanFrom = -1;
        menuSpanTo = -1;
    }

    // Hover-intent helpers. hoverPopout is what a bar button calls once the
    // pointer has rested on it long enough; the away timer closes it again when
    // the pointer is on neither a popout button nor the open card.
    function hoverPopout(name, anchor) {
        if (!Config.appearance.hoverMenus || barDragging)
            return;
        // A bar menu may take over from another bar menu, but hovering the bar
        // while a full-screen overlay is up must not close that overlay.
        if (launcherOpen || clipboardOpen || overviewOpen || settingsOpen || sidebarOpen)
            return;
        if (popout === name)
            return;
        togglePopout(name, anchor);
        hoverPop = true;
        armHoverAway();
    }

    function armHoverAway() {
        if (!hoverPop || hoverCard.length || hoverButtons > 0) {
            hoverAway.stop();
            return;
        }
        hoverAway.restart();
    }

    onHoverCardChanged: armHoverAway()
    onHoverButtonsChanged: armHoverAway()

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
        launcherReady = false;
        clipboardReady = false;
        overviewReady = false;
        settingsReady = false;
        sidebarReady = false;
        dropTimer.restart();
        if (name !== "tray")
            trayItem = null;
        popoutAnchor = anchor ?? popoutAnchor;
        popoutScreen = screenNameOf(anchor);
        if (!popoutScreen.length)
            popoutScreen = Compositor.focusedOutput;
        popoutKeep = name;
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
        launcherReady = false;
        clipboardReady = false;
        overviewReady = false;
        settingsReady = false;
        sidebarReady = false;
        dropTimer.restart();
        popoutAnchor = anchor ?? popoutAnchor;
        popoutScreen = screenNameOf(anchor);
        if (!popoutScreen.length)
            popoutScreen = Compositor.focusedOutput;
        popoutKeep = "tray";
        popout = "tray";
    }

    function clearPop() {
        popoutKeep = "";
        popoutAnchor = null;
        popoutScreen = "";
        trayItem = null;
        hoverPop = false;
        hoverCard = "";
        hoverAway.stop();
        clearMenuSpan();
    }

    function closePopout() {
        popout = "";
        clearPop();
    }

    function closeMenus() {
        popout = "";
        launcherOpen = false;
        clipboardOpen = false;
        overviewOpen = false;
        sidebarOpen = false;
        settingsOpen = false;
        sidebarScreen = "";
        overviewPick = "";
        overviewCount = 0;
        wallsOpen = false;
        clearMenuSpan();
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
        launcherReady = false;
        clipboardReady = false;
        overviewReady = false;
        settingsReady = false;
        sidebarReady = true;
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
        sidebarReady = false;
        launcherReady = true;
        launcherOpen = true;
        dropTimer.restart();
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
        launcherReady = false;
        sidebarReady = false;
        clipboardReady = true;
        clipboardOpen = true;
        dropTimer.restart();
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
        launcherReady = false;
        sidebarReady = false;
        settingsReady = true;
        if (!SettingsNav.pageOk(SettingsNav.page))
            SettingsNav.page = "system";
        settingsOpen = true;
        dropTimer.restart();
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
        launcherReady = false;
        sidebarReady = false;
        overviewPick = "";
        overviewCount = 0;
        overviewReady = true;
        overviewOpen = true;
        dropTimer.restart();
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
        id: hoverAway
        interval: root.hoverCloseDelay
        repeat: false
        onTriggered: if (root.hoverPop)
            root.closeMenus()
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
            if (!root.launcherOpen)
                root.launcherReady = false;
            if (!root.sidebarOpen)
                root.sidebarReady = false;
            if (!root.popout.length)
                root.clearPop();
        }
    }
}
