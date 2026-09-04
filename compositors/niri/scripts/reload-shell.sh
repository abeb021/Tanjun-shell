#!/usr/bin/env bash
# Super+Shift+R: restart the host. niri reloads its own config on save.
killall -q swayidle 2>/dev/null || true
killall -q quickshell 2>/dev/null || true
for _ in 1 2 3 4 5 6 7 8 9 10; do
  pgrep -x quickshell >/dev/null || break
  sleep 0.05
done
"$HOME/.local/share/tanjun/compositors/niri/scripts/idle.sh" >/dev/null 2>&1 &
exec quickshell
