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
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleClipboard
```

See `TODO.md` and `scripts/install-hypr.sh`.
