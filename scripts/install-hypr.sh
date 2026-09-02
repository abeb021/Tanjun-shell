#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HYPR="$HOME/.config/hypr/hyprland"
mkdir -p "$HOME/.config/tanjun"
if [[ ! -f "$HOME/.config/tanjun/state.json" ]]; then
  printf '%s\n' '{"kind":"dark","name":"monochrome"}' > "$HOME/.config/tanjun/state.json"
fi

QS="quickshell -p $ROOT"
IPC="quickshell ipc -p $ROOT call tanjun"

python3 - "$HYPR" "$ROOT" <<'PY'
import pathlib, sys
hypr, root = pathlib.Path(sys.argv[1]), sys.argv[2]
qs = f"quickshell -p {root}"
ipc = f"quickshell ipc -p {root} call tanjun"

auto = hypr / "autostart.lua"
text = auto.read_text()
old = 'hyprpaper --config ~/.config/hypr/hyprpaper.conf & waybar & swaync & hypridle & hyprsunset'
new = f'hyprpaper --config ~/.config/hypr/hyprpaper.conf & {qs} & hypridle & hyprsunset'
if old in text:
    auto.write_text(text.replace(old, new, 1))
    print(f"patched {auto}")
elif qs in text:
    print(f"already patched {auto}")
else:
    print(f"WARN: could not patch {auto}", file=sys.stderr)

binds = hypr / "binds.lua"
t = binds.read_text()
t2 = t.replace(
    'local menu = "wofi --show drun"',
    f'local menu = "{ipc} toggleLauncher"',
)
t2 = t2.replace(
    """hl.bind(mainMod .. " + V", hl.dsp.exec_cmd('cliphist list | wofi --dmenu --allow-image -p "Clipboard" | cliphist decode | wl-copy'))""",
    f'hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("{ipc} toggleClipboard"))',
)
t2 = t2.replace(
    'hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload && killall waybar && waybar && killall hyprpaper && hyprpaper && killall hyprsunset && hyprsunset"))',
    f'hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload && killall quickshell && {qs} && killall hyprpaper && hyprpaper && killall hyprsunset && hyprsunset"))',
)
if t2 != t:
    binds.write_text(t2)
    print(f"patched {binds}")
elif "toggleLauncher" in t:
    print(f"already patched {binds}")
else:
    print(f"WARN: could not patch {binds}", file=sys.stderr)
PY

echo
echo "Tanjun root: $ROOT"
echo "This session:"
echo "  killall waybar swaync 2>/dev/null || true"
echo "  $QS"
echo "IPC:"
echo "  $IPC toggleLauncher"
echo "  $IPC toggleSidebar"
echo "  $IPC toggleClipboard"
echo "  $IPC toggleDnd"
