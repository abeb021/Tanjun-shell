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
        active: UiMode.launcherReady
        Launcher {}
    }

    LazyLoader {
        active: UiMode.clipboardReady
        Clipboard {}
    }

    LazyLoader {
        active: UiMode.overviewReady
        Overview {}
    }

    LazyLoader {
        active: UiMode.settingsReady
        Settings {}
    }

    IpcHandler {
        target: "tanjun"

        property bool launcherOpen: UiMode.launcherOpen
        property bool settingsOpen: UiMode.settingsOpen
        property bool clipboardOpen: UiMode.clipboardOpen
        property bool sidebarOpen: UiMode.sidebarOpen
        property bool overviewOpen: UiMode.overviewOpen
        property bool dnd: UiMode.dnd
        property bool settingsReady: UiMode.settingsReady
        property bool overviewReady: UiMode.overviewReady
        property bool clipboardReady: UiMode.clipboardReady
        property bool launcherReady: UiMode.launcherReady
        property bool sidebarReady: UiMode.sidebarReady
        property string popout: UiMode.popout
        property string popoutKeep: UiMode.popoutKeep
        property string settingsPage: SettingsNav.page
        property int settingsRailCount: SettingsNav.railCount
        property int settingsRailH: SettingsNav.railH
        property int settingsScrollY: SettingsNav.scrollY
        property string style: Theme.style
        property string motion: Motion.kind
        property int settingsStyleCount: SettingsNav.styleCount
        property int settingsToggleGap: SettingsNav.toggleGap
        property int settingsToggleRadius: SettingsNav.toggleRadius
        property bool locked: Lock.locked
        property bool wallsOpen: UiMode.wallsOpen

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
            const rows = SettingsNav.pages;
            const ids = [];
            for (let i = 0; i < rows.length; i++)
                ids.push(rows[i].key);
            return JSON.stringify(ids);
        }

        function openSettingsPage(id: string): void {
            SettingsNav.openPage(id);
        }

        function pollJson(): string {
            return TestHooks.pollJson();
        }

        function hostCaps(): string {
            return TestHooks.hostCaps();
        }

        function settingsCatalog(): string {
            return TestHooks.settingsCatalog();
        }

        function uiMode(): string {
            return TestHooks.uiMode();
        }

        function sidebarJson(): string {
            return TestHooks.sidebarJson();
        }

        function popJson(): string {
            return TestHooks.popJson();
        }

        function snapScale(raw: string): string {
            return JSON.stringify(Screens.snapScale(Number(raw)));
        }

        function sunsetJson(): string {
            return Screens.sunsetJson();
        }

        function setSunset(raw: string): string {
            return Screens.applySunset(raw);
        }

        function deskJson(): string {
            return Screens.deskJson();
        }

        function setDesk(kind: string): string {
            Screens.setDesk(kind);
            return Screens.deskJson();
        }

        function idleJson(): string {
            return Idle.idleJson();
        }

        function setIdle(raw: string): string {
            return Idle.applyIdle(raw);
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

        function motionStyles(): string {
            return JSON.stringify(Motion.styleKeys());
        }

        function motionJson(): string {
            return JSON.stringify(Motion.snapshot());
        }

        function setMotion(id: string): string {
            Motion.setMotion(id);
            return JSON.stringify(Motion.snapshot());
        }

        function setTheme(kind: string, name: string): string {
            Theme.setTheme(kind, name);
            return JSON.stringify(Theme.snapshot());
        }

        function setWallpaper(path: string): string {
            Theme.setWallpaper(path);
            return path;
        }

        function setSampleWall(on: string): string {
            Theme.setSampleWall(on === "true" || on === "1");
            return JSON.stringify(!!Config.theme.sampleWall);
        }

        function openWalls(): void {
            UiMode.openWalls();
        }

        function setWallFolder(path: string): string {
            UiMode.setWallFolder(path);
            return UiMode.wallFolder;
        }

        function pickWall(path: string): string {
            UiMode.pickWall(path);
            return path;
        }

        function toggleLauncher(): void {
            UiMode.toggleLauncher();
        }

        function toggleSidebar(): void {
            UiMode.toggleSidebar();
        }

        function toggleAudio(): void {
            UiMode.togglePopout("audio");
        }

        function toggleNetwork(): void {
            UiMode.togglePopout("network");
        }

        function toggleCalendar(): void {
            UiMode.togglePopout("clock");
        }

        function toggleBattery(): void {
            UiMode.togglePopout("battery");
        }

        function toggleNotify(): void {
            UiMode.togglePopout("notify");
        }

        function toggleClipboard(): void {
            UiMode.toggleClipboard();
        }

        function toggleSettings(): void {
            UiMode.toggleSettings();
        }

        function toggleOverview(): void {
            Compositor.toggleOverview();
        }

        function confirmOverview(): void {
            UiMode.confirmOverview();
        }

        function toggleDnd(): void {
            UiMode.dnd = !UiMode.dnd;
        }

        function closeMenus(): void {
            UiMode.closeMenus();
        }

        function lock(): void {
            Lock.request();
        }

        function unlock(): void {
            Lock.unlock();
        }

        function lockJson(): string {
            return TestHooks.lockJson();
        }

        function logout(): void {
            Compositor.exitSession();
        }

        function launcherJson(): string {
            return TestHooks.launcherJson();
        }

        function workspaceJson(): string {
            return TestHooks.workspaceJson();
        }
    }
}
