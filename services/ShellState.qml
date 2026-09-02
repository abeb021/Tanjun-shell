pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string popout: ""
    property real popoutX: 0
    property var popoutAnchor: null

    property bool sidebarOpen: false
    property bool launcherOpen: false
    property bool clipboardOpen: false
    property bool dnd: false

    property string osdKind: ""
    property real osdValue: 0

    function togglePopout(name, anchor) {
        if (popout === name) {
            closePopout();
            return;
        }
        launcherOpen = false;
        clipboardOpen = false;
        popoutAnchor = anchor;
        popout = name;
    }

    function closePopout() {
        popout = "";
        popoutAnchor = null;
    }

    function toggleSidebar() {
        closePopout();
        launcherOpen = false;
        clipboardOpen = false;
        sidebarOpen = !sidebarOpen;
    }

    function toggleLauncher() {
        closePopout();
        sidebarOpen = false;
        clipboardOpen = false;
        launcherOpen = !launcherOpen;
    }

    function toggleClipboard() {
        closePopout();
        sidebarOpen = false;
        launcherOpen = false;
        clipboardOpen = !clipboardOpen;
    }

    function showOsd(kind, value) {
        osdKind = kind;
        osdValue = value;
        osdTimer.restart();
    }

    Timer {
        id: osdTimer
        interval: 1400
        onTriggered: root.osdKind = ""
    }
}
