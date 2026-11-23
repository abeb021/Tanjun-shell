<div align="center">

**単 Tanjun**

単純 — simple in structure, unmixed.

One [Quickshell](https://quickshell.outfoxxed.me) process. Hyprland or niri; the shell does not care.

### **[▶ Demo](docs/demo.webm)  -  [What you get](#what-you-get)  -  [Keys](#keys)  -  [Install](#install)  -  [Manual](#manual)**

</div>

| | |
|---|---|
| ![Launcher](docs/launcher.webp) | ![System drawer](docs/system.webp) |
| ![Settings](docs/settings.webp) | ![Calendar](docs/calendar.webp) |

## What you get

- **Quiet bar** — the distro mark (falls back to 単), desks, clock, load, a few glyphs. Click or rest on a glyph to open its panel, not a terminal.
- **Launcher** — rest card (clock, weather, track) until you type. Prefixes: `=` calc, `:` emoji, `/` wallpaper.
- **Overview** — live window previews. Super+Tab on Hyprland, Super+Grave on niri.
- **System drawer** — per-stream mixer, Bluetooth, Wi-Fi, VPN, host meters, power, skins.
- **Settings** — rail, live JSON pins, font picker, search. Super+Ctrl+,
- **Color** — nine hand-tuned skins, or **From wall**: matugen derives the palette from the wallpaper (Material You, smart dark/light). Keep the palette so a new wall cannot jump the rice.
- **Idle and lock** — dim, lock, DPMS, sleep in-shell. Fingerprint if PAM has it. Super+P.
- **Night light** — on/off, temperature, and a night/day schedule. hyprsunset on Hyprland, wl-gammarelay-rs on niri (the nix modules install it).
- **Wallpaper** — still or video. Lock uses a still frame.

## Keys

Compositor binds come from `scripts/setup.sh`. Left click or rest on a bar glyph opens its panel.

| Keybind | Action |
|---------|--------|
| `Super + A` | Launcher |
| `Super + Tab` | Overview (Hyprland) |
| `Super + Grave` | Overview (niri) |
| `Super + 1, 2, 3…` | Desk |
| `Super + Q` | kitty |
| `Super + E` | yazi (float 70%) |
| `Super + V` | Clipboard |
| `Super + C` | Close window |
| `Super + R` | Toggle float |
| `Super + B` | Pair buds |
| `Super + P` | Lock |
| `Super + O` | Logout |
| `Super + Ctrl + ,` | Settings |
| `Super + Space` | Keyboard layout |
| `Super + arrows` | Focus |
| `Super + H J K L` | Focus (niri) |
| `Super + Shift + arrows` | Resize |
| `Print` | Region screenshot |
| `Super + Print` | Window screenshot |
| `Alt + Print` | Active-output screenshot |

Summon without aiming at a glyph:

```bash
qs ipc call tanjun toggleLauncher
```

All binds: [docs/keys.md](docs/keys.md).

## Install

```bash
git clone https://github.com/abeb021/Tanjun-shell.git
cd Tanjun-shell
bash scripts/setup.sh --hyprland   # or --niri
```

Needs Quickshell on `PATH`. `setup.sh` links `shell/` to `~/.config/quickshell`, writes compositor autostart and binds, and copies lock PAM to `~/.config/tanjun/pam` (mode 600). Restart the compositor, or:

```bash
quickshell -p ~/.config/quickshell
```

> [!NOTE]
> PAM under `~/.config/tanjun/pam` is trusted like sudoers. Group- or world-writable files are refused.

## Manual

1. [Install](docs/install.md) — clone, rice, PAM
2. [Keys](docs/keys.md) — binds, bar clicks, launcher prefixes
3. [Config](docs/config.md) — JSON, color pick, style, wallpaper
4. [IPC](docs/ipc.md) — `qs ipc` verbs

Pins live in `~/.config/tanjun/config.json`. Copy [config.example.json](config.example.json) to start; omit a key and the default stays.

Widgets talk to `Compositor` only. Hyprland and niri each implement that contract.

```
shell/                  one Quickshell process
compositors/hyprland/   Lua rice
compositors/niri/       KDL rice
scripts/setup.sh        link, autostart, binds, PAM
tests/                  bash tests/run.sh
```

---

v3.6
