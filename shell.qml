//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import "services"
import "modules/bar"
import "modules/launcher"
import "modules/sidebar"
import "modules/osd"
import "modules/notifs"
import "modules/clipboard"

ShellRoot {
    Bar {}
    Launcher {}
    Sidebar {}
    Osd {}
    Toasts {}
    Clipboard {}

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

        function toggleDnd(): void {
            ShellState.dnd = !ShellState.dnd;
        }
    }
}
