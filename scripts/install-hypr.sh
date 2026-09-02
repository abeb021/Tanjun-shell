#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$HOME/.config/tanjun"
if [[ ! -f "$HOME/.config/tanjun/state.json" ]]; then
  printf '%s\n' '{"kind":"dark","name":"monochrome"}' > "$HOME/.config/tanjun/state.json"
fi

echo "Tanjun root: $ROOT"
echo
echo "1. Stop waybar + swaync for this session:"
echo "     killall waybar swaync 2>/dev/null || true"
echo "2. Start the shell:"
echo "     quickshell -p $ROOT"
echo "3. Hyprland autostart — replace waybar & swaync with:"
echo "     quickshell -p $ROOT"
echo "4. Binds (Lua):"
echo "     menu  = \"quickshell ipc -p $ROOT call tanjun toggleLauncher\""
echo "     clip  = \"quickshell ipc -p $ROOT call tanjun toggleClipboard\""
echo
echo "IPC:"
echo "  quickshell ipc -p $ROOT call tanjun toggleLauncher"
echo "  quickshell ipc -p $ROOT call tanjun toggleSidebar"
echo "  quickshell ipc -p $ROOT call tanjun toggleClipboard"
echo "  quickshell ipc -p $ROOT call tanjun toggleDnd"
