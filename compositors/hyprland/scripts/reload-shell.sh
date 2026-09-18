#!/usr/bin/env bash
# Super+Shift+R: reload Hyprland, then restart Quickshell.
# Host is ~/.config/quickshell (install plants that link). No clone path.
hyprctl reload >/dev/null 2>&1 || true
killall -q quickshell 2>/dev/null || true
for _ in 1 2 3 4 5 6 7 8 9 10; do
  pgrep -x quickshell >/dev/null || break
  sleep 0.05
done
exec quickshell
