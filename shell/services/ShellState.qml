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
    property string settingsPage: "system"
    property int settingsRailCount: 0
    property int settingsRailH: 0
    property int settingsScrollY: 0
    property int settingsStyleCount: 0
    readonly property var settingsPages: [
        { key: "system", label: "System", icon: "󰒓" },
        { key: "sound", label: "Sound", icon: "" },
        { key: "screen", label: "Screen", icon: "󰍹" },
        { key: "network", label: "Network", icon: "󰖩" },
        { key: "bluetooth", label: "Bluetooth", icon: "󰂯" },
        { key: "type", label: "Type", icon: "󰛖" },
        { key: "clock", label: "Clock", icon: "󰥔" },
        { key: "weather", label: "Weather", icon: "󰖕" },
        { key: "devices", label: "Devices", icon: "󰃠" },
        { key: "style", label: "Style", icon: "󰀼" },
        { key: "color", label: "Color", icon: "󰏘" }
    ]

    property bool launcherReady: false
    property bool clipboardReady: false
    property bool overviewReady: false
    property bool settingsReady: false

    property string osdKind: ""
    property real osdValue: 0

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
        settingsReady = true;
        if (!pageOk(settingsPage))
            settingsPage = "system";
        settingsOpen = true;
    }

    function pageOk(id) {
        const rows = settingsPages;
        for (let i = 0; i < rows.length; i++) {
            if (rows[i].key === id)
                return true;
        }
        return false;
    }

    function openSettingsPage(id) {
        if (!pageOk(id))
            return;
        settingsScrollY = 0;
        settingsPage = id;
        if (!settingsOpen)
            toggleSettings();
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
