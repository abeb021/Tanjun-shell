#!/usr/bin/env bash
# Super+Shift+R: restart Quickshell. niri reloads its config on save.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
wait_py="$here/../../../shell/scripts/tanjun-wait-qs.py"
state="${XDG_STATE_HOME:-$HOME/.local/state}/tanjun"
mkdir -p "$state"
log="$state/reload.log"
: >"$log"
{
  echo "=== $(date -Iseconds) ==="
  killall -q quickshell 2>/dev/null || true
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    pgrep -x quickshell >/dev/null || break
    sleep 0.1
  done
  if ! command -v quickshell >/dev/null; then
    echo "quickshell not on PATH"
    exit 1
  fi
} >>"$log" 2>&1
nohup quickshell --no-color >>"$log" 2>&1 &
pid=$!
if ! python3 "$wait_py" "$log" "$pid"; then
  echo "quickshell failed to load; see $log" >>"$log"
  kill "$pid" 2>/dev/null || true
  exit 1
fi
disown "$pid" 2>/dev/null || true
exit 0
