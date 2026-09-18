#!/usr/bin/env bash
# Super+Shift+R: restart Quickshell. niri reloads its config on save.
killall -q quickshell 2>/dev/null || true
for _ in 1 2 3 4 5 6 7 8 9 10; do
  pgrep -x quickshell >/dev/null || break
  sleep 0.05
done
exec quickshell
