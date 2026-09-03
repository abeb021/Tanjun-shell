#!/usr/bin/env bash
# Install Tanjun on any Arch Linux + Hyprland machine.
# Clone can live anywhere. This script never kills processes.
#
#   bash scripts/setup.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
HYPR="$CFG/hypr"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}/tanjun"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/tanjun"
QS="$CFG/quickshell"
STUB="$HYPR/hyprland.lua"

# extra (and AUR fallback). --needed skips what is already there.
PKGS=(
  hyprland
  quickshell
  hyprpaper
  hypridle
  hyprlock
  hyprsunset
  hyprshot
  cliphist
  wl-clipboard
  brightnessctl
  playerctl
  libqalculate
  kitty
  yazi
  bluez-utils
  python
  polkit-gnome
  ttf-jetbrains-mono
  noto-fonts-cjk
  ttf-nerd-fonts-symbols
)

link() {
  local target="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]]; then
    ln -sfn "$target" "$dest"
    echo "link  $dest -> $target"
    return 0
  fi
  if [[ -e "$dest" ]]; then
    echo "skip  $dest (exists, not a symlink)"
    return 1
  fi
  ln -sfn "$target" "$dest"
  echo "link  $dest -> $target"
}

pkg_ok() { /usr/bin/pacman -Qq "$1" >/dev/null 2>&1; }

install_pkgs() {
  if [[ ! -x /usr/bin/pacman ]]; then
    echo "need Arch Linux (pacman). Attach still runs."
    return 0
  fi
  local missing=() p
  for p in "${PKGS[@]}"; do
    pkg_ok "$p" || missing+=("$p")
  done
  if [[ ${#missing[@]} -eq 0 ]]; then
    echo "packages already present"
    return 0
  fi
  echo "install ${missing[*]}"
  local run=()
  if [[ "$(id -u)" -eq 0 ]]; then
    run=(/usr/bin/pacman)
  else
    run=(sudo /usr/bin/pacman)
  fi
  if "${run[@]}" -S --needed --noconfirm "${missing[@]}"; then
    return 0
  fi
  echo "pacman missed some names; trying AUR helper"
  local helper=""
  command -v yay >/dev/null && helper=yay
  command -v paru >/dev/null && helper=paru
  if [[ -z "$helper" ]]; then
    echo "install leftover packages by hand: ${missing[*]}"
    return 0
  fi
  local still=()
  for p in "${missing[@]}"; do
    pkg_ok "$p" || still+=("$p")
  done
  [[ ${#still[@]} -eq 0 ]] && return 0
  "$helper" -S --needed --noconfirm "${still[@]}" || echo "install leftover by hand: ${still[*]}"
}

attach() {
  mkdir -p "$STATE" "$HYPR/hyprland/themes/wall"
  link "$ROOT" "$DATA" || true
  link "$DATA/shell" "$QS" || true

  if [[ ! -f "$STATE/state.json" ]]; then
    printf '%s\n' '{"kind":"dark","name":"monochrome"}' > "$STATE/state.json"
  fi

  mkdir -p "$HYPR"
  if [[ -f "$STUB" ]] && ! grep -q "Tanjun compositor" "$STUB"; then
    cp "$STUB" "$STUB.bak-before-tanjun"
    echo "backup $STUB.bak-before-tanjun"
  fi
  cat > "$STUB" <<'EOF'
-- Tanjun compositor. Do not edit this stub.
local home = os.getenv("HOME") or ""
local data = os.getenv("XDG_DATA_HOME") or (home .. "/.local/share")
dofile(data .. "/tanjun/hyprland/hyprland.lua")
EOF
  echo "wrote $STUB"

  if [[ ! -f "$HYPR/hyprland/active_theme.lua" ]]; then
    mkdir -p "$HYPR/hyprland"
    printf '%s\n' 'return "hyprland.themes.dark.monochrome"' > "$HYPR/hyprland/active_theme.lua"
  fi

  chmod +x "$ROOT/hyprland/scripts/"*.sh "$ROOT/shell/scripts/"*.sh 2>/dev/null || true
}

echo "Tanjun setup"
echo "clone  $ROOT"
install_pkgs
attach
echo
echo "attached"
echo "  desktop    $DATA"
echo "  Quickshell $QS"
echo "  Hyprland   $STUB"
echo
echo "Next: Super+Shift+R  (or start a new Hyprland session)"
echo "Pins (optional): $CFG/tanjun/config.json"
echo "Outputs: Settings → screen  (writes ~/.config/hypr/monitors.lua)"
