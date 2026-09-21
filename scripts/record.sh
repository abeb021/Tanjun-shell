#!/usr/bin/env bash
# Desk 3 showcase. Opens every Tanjun surface in turn.
#
#   bash scripts/record.sh              # OBS record + tour → ~/Videos
#   bash scripts/record.sh --dry        # print the plan
#   bash scripts/record.sh --no-record  # tour only
#
# OBS must be able to record (Tools → WebSocket Server, or let this
# script start OBS). Needs a running Tanjun host. Super+Shift+R if ipc
# is missing. QS_PATH=/path/to/shell if ipc needs -p.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DESK=3
DRY=0
RECORD=1
OBS_PY="$ROOT/scripts/obs-rec.py"
OUTDIR="${RECORD_DIR:-$HOME/Videos}"

need() {
  command -v "$1" >/dev/null || {
    echo "need $1"
    exit 1
  }
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry) DRY=1 ;;
    --no-record) RECORD=0 ;;
    --desk)
      DESK="$2"
      shift
      ;;
    -h | --help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "unknown $1"
      exit 1
      ;;
  esac
  shift
done

log() {
  printf '%s\n' "$*"
}

ensure_unlocked() {
  log "unlock check"
  if [[ "$DRY" == 1 ]]; then
    return
  fi
  local raw
  if [[ -n "${QS_PATH:-}" ]]; then
    raw="$(quickshell ipc -p "$QS_PATH" prop get tanjun locked 2>/dev/null || true)"
  else
    raw="$(quickshell ipc prop get tanjun locked 2>/dev/null || quickshell ipc -p "$ROOT/shell" prop get tanjun locked 2>/dev/null || true)"
  fi
  if [[ "${raw,,}" == *true* ]]; then
    log "session is locked; unlock, then rerun"
    exit 1
  fi
}

desk() {
  log "desk $DESK"
  if [[ "$DRY" == 1 ]]; then
    return
  fi
  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl dispatch "hl.dsp.focus({ workspace = ${DESK} })" >/dev/null
    return
  fi
  if command -v hyprctl >/dev/null && hyprctl dispatch "hl.dsp.focus({ workspace = ${DESK} })" >/dev/null 2>&1; then
    return
  fi
  if [[ -n "${NIRI_SOCKET:-}" ]]; then
    niri msg action focus-workspace -- "$DESK" >/dev/null
  fi
}

ipc() {
  log "ipc $*"
  if [[ "$DRY" == 1 ]]; then
    return
  fi
  if [[ -n "${QS_PATH:-}" ]]; then
    quickshell ipc -p "$QS_PATH" call tanjun "$@"
    return
  fi
  quickshell ipc call tanjun "$@" 2>/dev/null && return
  quickshell ipc -p "$ROOT/shell" call tanjun "$@"
}

hold() {
  log "hold $1"
  if [[ "$DRY" == 1 ]]; then
    return
  fi
  sleep "$1"
}

PACE=1
SAVE_KIND=""
SAVE_NAME=""
SAVE_WALL=""
SAVE_SAMPLE=""

beat() {
  local t="$1"
  if [[ "$PACE" != "1" ]]; then
    t="$(awk -v t="$t" -v p="$PACE" 'BEGIN { printf "%.2f", t * p }')"
  fi
  hold "$t"
}

qs_call() {
  if [[ -n "${QS_PATH:-}" ]]; then
    quickshell ipc -p "$QS_PATH" call tanjun "$@"
    return
  fi
  quickshell ipc call tanjun "$@" 2>/dev/null && return
  quickshell ipc -p "$ROOT/shell" call tanjun "$@"
}

save_theme() {
  log "theme save"
  if [[ "$DRY" == 1 ]]; then
    return
  fi
  local raw
  raw="$(qs_call themeJson 2>/dev/null || true)"
  SAVE_KIND="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read() or "{}"); print(d.get("kind") or "")' <<<"$raw")"
  SAVE_NAME="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read() or "{}"); print(d.get("name") or "")' <<<"$raw")"
  SAVE_WALL="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read() or "{}"); print(d.get("wall") or "")' <<<"$raw")"
  SAVE_SAMPLE="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read() or "{}"); print("true" if d.get("sampleWall", True) else "false")' <<<"$raw")"
}

restore_theme() {
  log "theme restore"
  if [[ "$DRY" == 1 ]]; then
    log "ipc setTheme restore"
    return
  fi
  if [[ -n "$SAVE_SAMPLE" ]]; then
    qs_call setSampleWall "$SAVE_SAMPLE" >/dev/null || true
  fi
  if [[ "$SAVE_NAME" == "wall" && -n "$SAVE_WALL" ]]; then
    qs_call setWallpaper "$SAVE_WALL" >/dev/null || true
    return
  fi
  if [[ -n "$SAVE_KIND" && -n "$SAVE_NAME" ]]; then
    qs_call setTheme "$SAVE_KIND" "$SAVE_NAME" >/dev/null || true
  fi
}

arch_wall() {
  local d f
  for d in "$HOME/Pictures/Wallpapers" "$HOME/Pictures/wallpapers" "$HOME/pictures/wallpapers" "$HOME/pictures/Wallpapers"; do
    for f in "$d/logo.png" "$d/logo.jpg" "$d/logo.webp" "$d"/[Aa]rch*.png "$d"/[Aa]rch*.jpg; do
      if [[ -f "$f" ]]; then
        printf '%s\n' "$f"
        return
      fi
    done
  done
  printf '%s\n' "$HOME/Pictures/Wallpapers/logo.png"
}

pick_arch_wall() {
  local pics="$HOME/Pictures"
  local walls="$pics/Wallpapers"
  local logo
  logo="$(arch_wall)"
  if [[ -d "$HOME/Pictures/wallpapers" && ! -d "$HOME/Pictures/Wallpapers" ]]; then
    walls="$HOME/Pictures/wallpapers"
  fi
  log "wall folder $walls"
  log "ipc pickWall $logo"
  if [[ "$DRY" == 1 ]]; then
    ipc closeMenus
    ipc toggleSidebar
    ipc openWalls
    ipc setWallFolder "$pics"
    ipc setWallFolder "$walls"
    ipc setSampleWall true
    return
  fi
  if [[ ! -f "$logo" ]]; then
    log "need arch logo at $logo"
    exit 1
  fi
  ipc closeMenus
  hold 0.4
  ipc toggleSidebar
  hold 1.0
  ipc openWalls
  hold 1.2
  ipc setWallFolder "$pics"
  hold 0.9
  ipc setWallFolder "$walls"
  hold 1.6
  ipc setSampleWall true
  hold 0.3
  ipc pickWall "$logo"
  hold 2.2
}

rice_dir() {
  printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/assets/wallpapers"
}

rice_files() {
  local dir="$1"
  local f
  [[ -d "$dir" ]] || return 0
  shopt -s nullglob
  for f in "$dir"/*.jpg "$dir"/*.jpeg "$dir"/*.png "$dir"/*.webp "$dir"/*.bmp; do
    [[ -f "$f" ]] && printf '%s\n' "$f"
  done
  shopt -u nullglob
}

cycle_rice_walls() {
  local dir f
  dir="$(rice_dir)"
  log "wall folder $dir"
  ipc openWalls
  ipc setWallFolder "$dir"
  if [[ "$DRY" == 1 ]]; then
    hold 1.0
    if [[ -d "$dir" ]]; then
      while IFS= read -r f; do
        ipc setWallpaper "$f"
      done < <(rice_files "$dir")
    else
      ipc setWallpaper "$dir/emerald.jpg"
      ipc setWallpaper "$dir/obsidian.png"
    fi
    return
  fi
  hold 1.2
  if [[ ! -d "$dir" ]]; then
    log "need $dir"
    return
  fi
  while IFS= read -r f; do
    ipc setWallpaper "$f"
    hold 1.0
  done < <(rice_files "$dir")
}

tour() {
  ipc closeMenus
  beat 0.6

  ipc toggleLauncher
  beat 2.2
  ipc closeMenus
  beat 0.45

  ipc toggleAudio
  beat 1.6
  ipc closeMenus
  beat 0.35

  ipc toggleNetwork
  beat 1.6
  ipc closeMenus
  beat 0.35

  ipc toggleCalendar
  beat 1.5
  ipc closeMenus
  beat 0.35

  ipc toggleBattery
  beat 1.4
  ipc closeMenus
  beat 0.35

  ipc toggleNotify
  beat 1.5
  ipc closeMenus
  beat 0.35

  ipc toggleClipboard
  beat 1.8
  ipc closeMenus
  beat 0.4

  ipc toggleOverview
  beat 2.4
  ipc closeMenus
  beat 0.5

  ipc toggleSidebar
  beat 2.2
  ipc closeMenus
  beat 0.45

  ipc toggleSettings
  beat 1.2
  for page in system sound screen network bluetooth type clock weather devices style color; do
    ipc openSettingsPage "$page"
    beat 1.15
  done
  ipc closeMenus
  beat 0.5
}

obs_py() {
  python3 "$OBS_PY" "$1" "$OUTDIR"
}

obs_listening() {
  python3 -c 'import socket; s=socket.socket(); s.settimeout(0.4); s.connect(("127.0.0.1", 4455)); s.close()' 2>/dev/null
}

obs_start() {
  log "obs start"
  log "record dir $OUTDIR"
  if [[ "$DRY" == 1 ]]; then
    return
  fi
  mkdir -p "$OUTDIR"
  need obs
  if obs_py start; then
    return
  fi
  if pgrep -x obs >/dev/null && ! obs_listening; then
    log "OBS is open but WebSocket is off (port 4455)."
    log "OBS → Tools → WebSocket Server Settings → Enable, then restart OBS."
    log "Then: bash scripts/record.sh"
    exit 1
  fi
  if ! pgrep -x obs >/dev/null; then
    obs --minimize-to-tray >/dev/null 2>&1 &
    local i
    for i in $(seq 1 25); do
      hold 0.4
      if obs_listening && obs_py start; then
        return
      fi
    done
  fi
  log "could not start OBS recording"
  exit 1
}

obs_stop() {
  log "obs stop"
  if [[ "$DRY" == 1 ]]; then
    log "wrote $OUTDIR"
    return
  fi
  local path rc
  set +e
  path="$(obs_py stop)"
  rc=$?
  set -e
  path="${path##*$'\n'}"
  if [[ "$rc" -ne 0 || -z "$path" || ! -e "$path" ]]; then
    log "OBS did not save a file into $OUTDIR"
    exit 1
  fi
  log "wrote $path"
}

if [[ "$DRY" == 1 ]]; then
  desk
  ensure_unlocked
  save_theme
  if [[ "$RECORD" == 1 ]]; then
    obs_start
  fi
  tour
  pick_arch_wall
  cycle_rice_walls
  restore_theme
  if [[ "$RECORD" == 1 ]]; then
    obs_stop
  fi
  log "dry done"
  exit 0
fi

need quickshell
desk
ensure_unlocked
save_theme
hold 0.4

INH_PID=""
if command -v systemd-inhibit >/dev/null; then
  systemd-inhibit --what=idle:sleep --who=tanjun --why=showcase --mode=block sleep 3600 &
  INH_PID=$!
fi

REC_ON=0
trap 'restore_theme || true; ipc closeMenus || true; if [[ "$REC_ON" == 1 ]]; then obs_stop || true; fi; if [[ -n "$INH_PID" ]]; then kill "$INH_PID" 2>/dev/null || true; fi' EXIT

if [[ "$RECORD" == 1 ]]; then
  obs_start
  REC_ON=1
  hold 0.6
fi

tour
pick_arch_wall
cycle_rice_walls
restore_theme

if [[ "$RECORD" == 1 ]]; then
  obs_stop
  REC_ON=0
fi
trap - EXIT
if [[ -n "$INH_PID" ]]; then
  kill "$INH_PID" 2>/dev/null || true
fi
ipc closeMenus
log "tour done"
