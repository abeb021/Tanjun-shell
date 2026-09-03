#!/usr/bin/env bash
# Full-frame README shots. Scale only, no crop.
#
#   bash scripts/shots.sh
#
# Needs grim + magick and a running Tanjun host. Super+Shift+R if
# closeMenus is missing. QS_PATH=/path/to/shell if ipc needs -p.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCS="$ROOT/docs"
TMP="$DOCS/_full.png"

need() {
  command -v "$1" >/dev/null || {
    echo "need $1"
    exit 1
  }
}

need grim
need magick
need quickshell
mkdir -p "$DOCS"

ipc() {
  local verb="$1"
  if [[ -n "${QS_PATH:-}" ]]; then
    quickshell ipc -p "$QS_PATH" call tanjun "$verb"
    return
  fi
  quickshell ipc call tanjun "$verb" 2>/dev/null && return
  quickshell ipc -p "$ROOT/shell" call tanjun "$verb"
}

to_webp() {
  magick "$1" -resize 1280x -unsharp 0x0.5 -strip -quality 86 "$2"
}

shot() {
  grim "$TMP"
  to_webp "$TMP" "$DOCS/$1.webp"
  echo "wrote  docs/$1.webp"
}

settle() {
  sleep "$1"
}

ipc closeMenus
settle 0.45
shot desktop

ipc toggleLauncher
settle 0.7
shot launcher
ipc closeMenus
settle 0.4

ipc toggleSettings
settle 0.7
shot settings
ipc closeMenus
settle 0.4

ipc toggleSidebar
settle 0.65
shot system
ipc closeMenus
settle 0.4

ipc toggleCalendar
settle 0.5
shot calendar
ipc closeMenus
settle 0.35

rm -f "$TMP"
echo "done"
