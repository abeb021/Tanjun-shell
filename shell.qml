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

ShellRoot {
    Bar {}
    Launcher {}
    Osd {}
    Toasts {}
    Clipboard {}
    Overview {}

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
