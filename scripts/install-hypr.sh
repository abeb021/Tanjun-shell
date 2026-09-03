#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HYPR="$HOME/.config/hypr/hyprland"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
mkdir -p "$STATE_HOME/tanjun"
if [[ ! -f "$STATE_HOME/tanjun/state.json" ]]; then
  if [[ -f "$HOME/.config/tanjun/state.json" ]]; then
    cp "$HOME/.config/tanjun/state.json" "$STATE_HOME/tanjun/state.json"
  else
    printf '%s\n' '{"kind":"dark","name":"monochrome"}' > "$STATE_HOME/tanjun/state.json"
  fi
fi

QS="quickshell -p $ROOT"
IPC="quickshell ipc -p $ROOT call tanjun"

python3 - "$HYPR" "$ROOT" <<'PY'
import pathlib, sys
hypr, root = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
qs = f"quickshell -p {root}"
ipc = f"quickshell ipc -p {root} call tanjun"

auto = hypr / "autostart.lua"
text = auto.read_text()
old = "hyprpaper --config ~/.config/hypr/hyprpaper.conf & waybar & swaync & hypridle & hyprsunset"
new = f"hyprpaper --config ~/.config/hypr/hyprpaper.conf & {qs} & hypridle & hyprsunset"
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
reload = f'hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload; killall quickshell; {qs} &"))'
for old in (
    'hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload && killall waybar && waybar && killall hyprpaper && hyprpaper && killall hyprsunset && hyprsunset"))',
    'hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload && killall quickshell && ' + qs + ' && killall hyprpaper && hyprpaper && killall hyprsunset && hyprsunset"))',
    'hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload; killall quickshell; ' + qs + ' & killall hyprpaper; hyprpaper & killall hyprsunset; hyprsunset &"))',
):
    t2 = t2.replace(old, reload)
t2 = t2.replace(
    'hl.bind(mainMod .. " + tab", hl.dsp.window.cycle_next())\nhl.bind(mainMod .. " + tab", hl.dsp.window.bring_to_top())',
    f'hl.bind(mainMod .. " + tab", hl.dsp.exec_cmd("{ipc} toggleOverview"))',
)
for old in (
    f'hl.bind(mainMod .. " + tab", hl.dsp.exec_cmd("{ipc} toggleOverview"), {{ allow_input_capture = true }})\nhl.bind("SUPER_L", hl.dsp.exec_cmd("{ipc} confirmOverview"), {{ release = true, allow_input_capture = true }})\nhl.bind("SUPER_R", hl.dsp.exec_cmd("{ipc} confirmOverview"), {{ release = true, allow_input_capture = true }})',
    f'hl.bind(mainMod .. " + tab", hl.dsp.exec_cmd("{ipc} toggleOverview"), {{ allow_input_capture = true }})',
):
    t2 = t2.replace(old, f'hl.bind(mainMod .. " + tab", hl.dsp.exec_cmd("{ipc} toggleOverview"))')

start, end = "-- Tanjun summon", "-- /Tanjun summon"
block = "\n".join([
    start,
    f'hl.bind(mainMod .. " + CTRL + A", hl.dsp.exec_cmd("{ipc} toggleAudio"))',
    f'hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd("{ipc} toggleNetwork"))',
    f'hl.bind(mainMod .. " + CTRL + C", hl.dsp.exec_cmd("{ipc} toggleCalendar"))',
    f'hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd("{ipc} toggleBattery"))',
    f'hl.bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd("{ipc} toggleNotify"))',
    f'hl.bind(mainMod .. " + CTRL + S", hl.dsp.exec_cmd("{ipc} toggleSidebar"))',
    f'hl.bind(mainMod .. " + CTRL + comma", hl.dsp.exec_cmd("{ipc} toggleSettings"))',
    f'hl.bind(mainMod .. " + CTRL + D", hl.dsp.exec_cmd("{ipc} toggleDnd"))',
    end,
])
if start in t2:
    i = t2.index(start)
    j = t2.index(end, i) + len(end) if end in t2[i:] else i + len(start)
    t2 = t2[:i] + block + t2[j:]
else:
    t2 = t2.rstrip() + "\n\n" + block + "\n"

if t2 != t:
    binds.write_text(t2)
    print(f"patched {binds}")
else:
    print(f"already patched {binds}")

rules = hypr / "rules.lua"
rt = rules.read_text()
rstart, rend = "-- Tanjun layers", "-- /Tanjun layers"
rblock = "\n".join([
    rstart,
    "for _, ns in ipairs({",
    '    "tanjun-bar",',
    '    "tanjun-sidebar",',
    '    "tanjun-launcher",',
    '    "tanjun-clipboard",',
    '    "tanjun-overview",',
    '    "tanjun-settings",',
    '    "tanjun-osd",',
    '    "tanjun-toast",',
    "}) do",
    "    hl.layer_rule({",
    "        match = {",
    "            namespace = ns,",
    "        },",
    "        no_anim = true,",
    "    })",
    "end",
    rend,
])
if rstart in rt:
    i = rt.index(rstart)
    j = rt.index(rend, i) + len(rend) if rend in rt[i:] else i + len(rstart)
    rt2 = rt[:i] + rblock + rt[j:]
else:
    rt2 = rt.rstrip() + "\n\n" + rblock + "\n"
if rt2 != rt:
    rules.write_text(rt2)
    print(f"patched {rules}")
else:
    print(f"already patched {rules}")
PY

echo
echo "Tanjun root: $ROOT"
echo "This session:"
echo "  killall waybar swaync 2>/dev/null || true"
echo "  $QS"
echo "IPC:"
echo "  $IPC toggleLauncher"
echo "  $IPC toggleSidebar"
echo "  $IPC toggleSettings"
echo "  $IPC toggleAudio"
echo "  $IPC toggleNetwork"
echo "  $IPC toggleCalendar"
echo "  $IPC toggleBattery"
echo "  $IPC toggleNotify"
echo "  $IPC toggleClipboard"
echo "  $IPC toggleOverview"
echo "  $IPC confirmOverview"
echo "  $IPC toggleDnd"
