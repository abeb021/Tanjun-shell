#!/usr/bin/env bash
# Link Quickshell and the chosen compositor config. Does not kill processes.
#
#   bash scripts/setup.sh              # pick compositor (tty) or detect
#   bash scripts/setup.sh --hyprland
#   bash scripts/setup.sh --niri
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
HYPR="$CFG/hypr"
NIRI="$CFG/niri"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}/tanjun"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/tanjun"
QS="$CFG/quickshell"
STUB="$HYPR/hyprland.lua"

COMPOSITOR=""
FORCE_PICK=1
for arg in "$@"; do
  case "$arg" in
    --niri) COMPOSITOR=niri; FORCE_PICK=0 ;;
    --hyprland|--hypr) COMPOSITOR=hyprland; FORCE_PICK=0 ;;
    -h|--help)
      echo "usage: bash scripts/setup.sh [--hyprland|--niri]"
      echo "  no flag  pick compositor (tty) or detect from this session"
      exit 0
      ;;
  esac
done

R= DIM= SEAL= TITLE= MUTE=
palette() {
  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    R=$'\033[0m'
    DIM=$'\033[38;2;150;150;150m'
    SEAL=$'\033[38;2;224;224;224m'
    TITLE=$'\033[1;38;2;220;220;220m'
    MUTE=$'\033[38;2;90;90;90m'
  else
    R= DIM= SEAL= TITLE= MUTE=
  fi
}

detect_compositor() {
  local desk="${XDG_CURRENT_DESKTOP:-}"
  if [[ -n "${NIRI_SOCKET:-}" || "$desk" == *[Nn]iri* ]]; then
    printf '%s' niri
  else
    printf '%s' hyprland
  fi
}

banner() {
  palette
  local art=(
    " █▄     █▄     ▄█   "
    " ▀██    ▀██   ██▀   "
    "  ████████████████  "
    "  ██     ██     ██  "
    "  ████████████████  "
    "  ██     ██     ██  "
    "  ████████████████  "
    "         ██         "
    " ██████████████████ "
    "         ██         "
    "         ▀▀         "
  )
  local copy=(
    "${TITLE}単純${R}  ${TITLE}Tanjun${R}"
    ""
    "${DIM}simple in structure${R}"
    "${DIM}unmixed, one quiet process${R}"
    "${DIM}seal opens, frame off${R}"
    ""
    ""
    ""
    ""
    ""
    ""
  )

  printf '\n'
  local i
  for i in "${!art[@]}"; do
    printf '  %s%s%s    %s\n' "$SEAL" "${art[$i]}" "$R" "${copy[$i]}"
  done
  printf '  %sclone  %s%s%s\n' "$MUTE" "$DIM" "$ROOT" "$R"
  printf '\n'
}

pick_read() {
  local k rest
  IFS= read -r -n1 -s k || return 1
  if [[ "$k" == $'\x1b' ]]; then
    IFS= read -r -n1 -s -t 0.05 rest || true
    if [[ "$rest" == "[" ]]; then
      IFS= read -r -n1 -s -t 0.05 rest || true
      case "$rest" in
        A) printf '%s' up ;;
        B) printf '%s' down ;;
        *) printf '%s' esc ;;
      esac
      return 0
    fi
    printf '%s' esc
    return 0
  fi
  case "$k" in
    j|J|n|N) printf '%s' down ;;
    k|K|p|P) printf '%s' up ;;
    1) printf '%s' one ;;
    2) printf '%s' two ;;
    q|Q) printf '%s' quit ;;
    ""|$'\n'|$'\r') printf '%s' enter ;;
    *) printf '%s' other ;;
  esac
}

pick_draw() {
  local idx="$1" here="$2"
  local mark0="   " mark1="   " n0="$MUTE" n1="$MUTE" d0="$MUTE" d1="$MUTE"
  local here0="" here1=""
  if [[ "$here" == hyprland ]]; then
    here0="  ${MUTE}this session${R}"
  else
    here1="  ${MUTE}this session${R}"
  fi
  if [[ "$idx" -eq 0 ]]; then
    mark0="${SEAL}単 ${R}"
    n0="$TITLE"
    d0="$DIM"
  else
    mark1="${SEAL}単 ${R}"
    n1="$TITLE"
    d1="$DIM"
  fi
  printf '  %scompositor%s\n' "$MUTE" "$R"
  printf '\n'
  printf '  %s%sHyprland%s%s\n' "$mark0" "$n0" "$R" "$here0"
  printf '     %slua rice · numbered desks%s\n' "$d0" "$R"
  printf '\n'
  printf '  %s%sniri%s%s\n' "$mark1" "$n1" "$R" "$here1"
  printf '     %sscroll tiling · kdl%s\n' "$d1" "$R"
  printf '\n'
  printf '  %sj/k · enter · q%s\n' "$MUTE" "$R"
}

pick_compositor() {
  local here idx key
  local -i lines=9
  here="$(detect_compositor)"
  if [[ "$FORCE_PICK" -eq 0 ]]; then
    printf '  %spicked  %s%s%s\n\n' "$MUTE" "$TITLE" "$COMPOSITOR" "$R"
    return 0
  fi
  if [[ ! -t 0 || ! -t 1 ]]; then
    COMPOSITOR="$here"
    printf '  %spicked  %s%s%s  %s(detected)%s\n\n' "$MUTE" "$TITLE" "$COMPOSITOR" "$R" "$MUTE" "$R"
    return 0
  fi

  idx=0
  [[ "$here" == niri ]] && idx=1

  local saved
  saved="$(stty -g)"
  printf '\033[?25l'
  trap 'stty "$saved" 2>/dev/null || true; printf "\033[?25h"; exit 130' INT TERM
  stty -echo -icanon min 1 time 0

  pick_draw "$idx" "$here"
  while true; do
    key="$(pick_read || true)"
    case "$key" in
      up) idx=0 ;;
      down) idx=1 ;;
      one) idx=0 ;;
      two) idx=1 ;;
      enter)
        stty "$saved"
        printf '\033[?25h'
        trap - INT TERM
        if [[ "$idx" -eq 1 ]]; then
          COMPOSITOR=niri
        else
          COMPOSITOR=hyprland
        fi
        printf '\033[%sA\033[J' "$lines"
        printf '  %spicked  %s%s%s\n\n' "$MUTE" "$TITLE" "$COMPOSITOR" "$R"
        return 0
        ;;
      quit|esc)
        stty "$saved"
        printf '\033[?25h'
        trap - INT TERM
        printf '\n'
        echo "aborted"
        exit 1
        ;;
      other|"") continue ;;
    esac
    printf '\033[%sA' "$lines"
    pick_draw "$idx" "$here"
  done
}

# extra (and AUR fallback). --needed skips what is already there.
PKGS_COMMON=(
  quickshell
  cliphist
  wl-clipboard
  brightnessctl
  playerctl
  libqalculate
  kitty
  yazi
  bluez-utils
  python
  ffmpeg
  mpvpaper
  ttf-jetbrains-mono
  noto-fonts-cjk
  ttf-nerd-fonts-symbols
)
PKGS_HYPR=(
  hyprland
  hyprpaper
  hyprsunset
  hyprshot
)
PKGS_NIRI=(
  niri
  swaybg
  xwayland-satellite
)

build_pkgs() {
  PKGS=("${PKGS_COMMON[@]}")
  if [[ "$COMPOSITOR" == niri ]]; then
    PKGS+=("${PKGS_NIRI[@]}")
  else
    PKGS+=("${PKGS_HYPR[@]}")
  fi
}

link() {
  local target="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]]; then
    ln -sfn "$target" "$dest"
    echo "link  $dest -> $target"
    return 0
  fi
  if [[ -e "$dest" ]]; then
    echo "skip  $dest (exists, not a symlink). Point it at $target yourself or remove it and re-run."
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

attach_hypr() {
  mkdir -p "$HYPR/hyprland/themes/wall"
  if [[ -f "$STUB" ]] && ! grep -q "Tanjun" "$STUB"; then
    cp "$STUB" "$STUB.bak-before-tanjun"
    echo "backup $STUB.bak-before-tanjun (replacing compositor stub)"
  fi
  cat > "$STUB" <<'EOF'
-- Tanjun. Monitors: ~/.config/hypr/monitors.lua
local home = os.getenv("HOME") or ""
local data = os.getenv("XDG_DATA_HOME") or (home .. "/.local/share")
dofile(data .. "/tanjun/compositors/hyprland/hyprland.lua")
EOF
  echo "wrote $STUB"

  if [[ ! -f "$HYPR/hyprland/active_theme.lua" ]]; then
    mkdir -p "$HYPR/hyprland"
    printf '%s\n' 'return "hyprland.themes.dark.monochrome"' > "$HYPR/hyprland/active_theme.lua"
  fi
}

attach_niri() {
  mkdir -p "$NIRI"
  local stub="$NIRI/config.kdl"
  if [[ -f "$stub" ]] && ! grep -q "Tanjun" "$stub"; then
    cp "$stub" "$stub.bak-before-tanjun"
    echo "backup $stub.bak-before-tanjun (replacing compositor stub)"
  fi
  link "$ROOT/compositors/niri" "$NIRI/tanjun" || true
  cat > "$stub" <<'EOF'
// Tanjun. Outputs: output.kdl
include "tanjun/config.kdl"
include "output.kdl"
EOF
  echo "wrote $stub"
  if [[ ! -f "$NIRI/output.kdl" ]]; then
    printf '%s\n' '// Outputs. Settings → screen writes this file.' > "$NIRI/output.kdl"
    echo "wrote $NIRI/output.kdl"
  fi
}

attach() {
  mkdir -p "$STATE"
  link "$ROOT" "$DATA" || true
  link "$DATA/shell" "$QS" || true

  if [[ ! -f "$STATE/state.json" ]]; then
    printf '%s\n' '{"kind":"dark","name":"monochrome"}' > "$STATE/state.json"
  fi

  chmod +x "$ROOT/scripts/"*.sh "$ROOT/compositors/hyprland/scripts/"*.sh "$ROOT/compositors/niri/scripts/"*.sh "$ROOT/shell/scripts/"*.sh 2>/dev/null || true

  if [[ "$COMPOSITOR" == niri ]]; then
    attach_niri
  else
    attach_hypr
  fi
}

banner
pick_compositor
COMPOSITOR="${COMPOSITOR:-$(detect_compositor)}"
build_pkgs
install_pkgs
attach
echo
echo "attached"
echo "  desktop    $DATA"
echo "  Quickshell $QS"
if [[ "$COMPOSITOR" == niri ]]; then
  echo "  niri       $NIRI/config.kdl"
  echo
  echo "Next: start a niri session (or niri msg action quit && niri)"
  echo "Outputs: Settings → screen  (writes ~/.config/niri/output.kdl)"
else
  echo "  Hyprland   $STUB"
  echo
  echo "Next: Super+Shift+R  (or start a new Hyprland session)"
  echo "Outputs: Settings → screen  (writes ~/.config/hypr/monitors.lua)"
fi
echo "Pins (optional): $CFG/tanjun/config.json"
