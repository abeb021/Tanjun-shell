# Tanjun 単純

Quickshell desktop for this Hyprland machine. Frame off. Quiet bar. Rest-card launcher. Named palettes.

```
killall waybar swaync
quickshell -p ~/Programming/Tanjun-shell
```

IPC:

```
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleLauncher
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleSidebar
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleAudio
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleNetwork
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleCalendar
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleBattery
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleNotify
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleClipboard
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleOverview
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleDnd
```

Panels: Super+Ctrl+A audio · W network · C calendar · B battery · N notify · S 単 · D do-not-disturb.

See `TODO.md` and `scripts/install-hypr.sh`.
