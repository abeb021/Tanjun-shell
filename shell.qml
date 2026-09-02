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
import "modules/sidebar"

ShellRoot {
    Bar {}
    Launcher {}
    Osd {}
    Toasts {}
    Clipboard {}
    Overview {}
    Sidebar {}

    IpcHandler {
        target: "tanjun"

        function ping(): string {
            return "単";
        }

        function toggleLauncher(): void {
            ShellState.toggleLauncher();
        }

        function toggleSidebar(): void {
            ShellState.toggleSidebar();
        }

        function toggleMenu(): void {
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

        function toggleOverview(): void {
            ShellState.toggleOverview();
        }

        function confirmOverview(): void {
            ShellState.confirmOverview();
        }

        function toggleDnd(): void {
            ShellState.dnd = !ShellState.dnd;
        }
    }
}
