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

    IpcHandler {
        target: "tanjun"

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
