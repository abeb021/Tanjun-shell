//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import "services"
import "modules/bar"
import "modules/launcher"
import "modules/osd"
import "modules/notifs"
import "modules/clipboard"
import "modules/overview"
import "modules/settings"
import "modules/lock"
import "modules/polkit"

ShellRoot {
    property bool _idle: Idle.watching

    Bar {}
    Osd {}
    Toasts {}
    SessionLock {}
    PolkitAsk {}

    LazyLoader {
        active: ShellState.launcherReady
        Launcher {}
    }

    LazyLoader {
        active: ShellState.clipboardReady
        Clipboard {}
    }

    LazyLoader {
        active: ShellState.overviewReady
        Overview {}
    }

    LazyLoader {
        active: ShellState.settingsReady
        Settings {}
    }

    Timer {
        interval: 800
        running: !ShellState.settingsReady
        repeat: false
        onTriggered: ShellState.settingsReady = true
    }

    IpcHandler {
        target: "tanjun"

        property bool launcherOpen: ShellState.launcherOpen
        property bool settingsOpen: ShellState.settingsOpen
        property bool clipboardOpen: ShellState.clipboardOpen
        property bool sidebarOpen: ShellState.sidebarOpen
        property bool overviewOpen: ShellState.overviewOpen
        property bool dnd: ShellState.dnd
        property string popout: ShellState.popout
        property string settingsPage: ShellState.settingsPage
        property int settingsRailCount: ShellState.settingsRailCount
        property int settingsRailH: ShellState.settingsRailH
        property int settingsScrollY: ShellState.settingsScrollY
        property string style: Theme.style
        property int settingsStyleCount: ShellState.settingsStyleCount

        function ping(): string {
            return "ok";
        }

        function themeJson(): string {
            return JSON.stringify(Theme.snapshot());
        }

        function configJson(): string {
            return JSON.stringify(Config.sparseObject());
        }

        function settingsPages(): string {
            const rows = ShellState.settingsPages;
            const ids = [];
            for (let i = 0; i < rows.length; i++)
                ids.push(rows[i].key);
            return JSON.stringify(ids);
        }

        function openSettingsPage(id: string): void {
            ShellState.openSettingsPage(id);
        }

        function snapScale(raw: string): string {
            return JSON.stringify(Screens.snapScale(Number(raw)));
        }

        function styles(): string {
            return JSON.stringify(Theme.styleKeys());
        }

        function styleJson(): string {
            return JSON.stringify(Theme.styleChrome());
        }

        function setStyle(id: string): string {
            Theme.setStyle(id);
            return JSON.stringify(Theme.style);
        }

        function toggleLauncher(): void {
            ShellState.toggleLauncher();
        }

        function toggleSidebar(): void {
            ShellState.toggleSidebar();
        }

        function toggleAudio(): void {
            ShellState.togglePopout("audio");
        }

        function toggleNetwork(): void {
            ShellState.togglePopout("network");
        }

        function toggleCalendar(): void {
            ShellState.togglePopout("clock");
        }

        function toggleBattery(): void {
            ShellState.togglePopout("battery");
        }

        function toggleNotify(): void {
            ShellState.togglePopout("notify");
        }

        function toggleClipboard(): void {
            ShellState.toggleClipboard();
        }

        function toggleSettings(): void {
            ShellState.toggleSettings();
        }

        function toggleOverview(): void {
            Compositor.toggleOverview();
        }

        function confirmOverview(): void {
            ShellState.confirmOverview();
        }

        function toggleDnd(): void {
            ShellState.dnd = !ShellState.dnd;
        }

        function closeMenus(): void {
            ShellState.closeMenus();
        }

        function lock(): void {
            Lock.request();
        }
    }
}
