# Tanjun

Wayland desktop shell ([Quickshell](https://quickshell.outfoxxed.me)). Hyprland or niri. Bar, launcher, notifications, clipboard, settings, lock — one process.

![Bar on an empty desk](docs/desktop.webp)

## Install

Arch. From the clone:

```
bash scripts/setup.sh
```

`--hyprland` / `--niri` skip the picker. Does not kill running processes. Super+Shift+R (or a new session) picks it up.

| Path | Points at |
| --- | --- |
| `~/.local/share/tanjun` | this clone |
| `~/.config/quickshell` | `shell/` |
| `~/.config/hypr/hyprland.lua` | `compositors/hyprland/` (Hyprland) |
| `~/.config/niri/config.kdl` | `compositors/niri/` (niri) |
| `~/.config/tanjun/config.json` | optional pins |

Outputs: Settings → screen (`~/.config/hypr/monitors.lua` or `~/.config/niri/output.kdl`).

## Screenshots

![Launcher](docs/launcher.webp)

![Settings](docs/settings.webp)

![Calendar](docs/calendar.webp)

![System](docs/system.webp)

## Binds

`compositors/hyprland/modules/binds.lua` and `compositors/niri/config/keybinds.kdl`.

| Bind | |
| --- | --- |
| Super+A | Launcher |
| Super+V | Clipboard |
| Super+Tab | Overview |
| Super+Shift+S | Region screenshot |
| Print | Region screenshot |
| Super+Ctrl+A | Mixer |
| Super+Ctrl+W | Network |
| Super+Ctrl+C | Calendar |
| Super+Ctrl+B | Battery |
| Super+Ctrl+N | Notifications |
| Super+Ctrl+S | System |
| Super+Ctrl+, | Settings |
| Ctrl+K | Search in settings |
| Super+Ctrl+D | DND |
| Super+L | Lock |
| Super+1 … 0 | Desks |
| Escape | Close |

Click a bar icon for its panel. Scroll / right / middle: volume, mute, timezone, DND, backlight. Right-click a desk number moves the focused window.

Launcher: type to search. `=` calc, `;` clipboard, `?` web, `/` actions, `@` music. Down lists apps.

## IPC

```
quickshell ipc call tanjun toggleLauncher
quickshell ipc call tanjun toggleSidebar
quickshell ipc call tanjun toggleAudio
quickshell ipc call tanjun toggleNetwork
quickshell ipc call tanjun toggleCalendar
quickshell ipc call tanjun toggleBattery
quickshell ipc call tanjun toggleNotify
quickshell ipc call tanjun toggleClipboard
quickshell ipc call tanjun toggleSettings
quickshell ipc call tanjun toggleOverview
quickshell ipc call tanjun toggleDnd
quickshell ipc call tanjun closeMenus
quickshell ipc call tanjun lock
```

## Config

Optional. Defaults are in the shell. Pin only what you want. See `config.example.json`.

```
{
  "clock": {
    "zones": [
      { "id": "Europe/Berlin", "label": "Berlin" }
    ]
  },
  "services": {
    "weatherCity": "Berlin"
  }
}
```

| Key | Empty |
| --- | --- |
| `clock.zones` | system timezone |
| `clock.twelveHour` | locale |
| `services.weatherCity` | wttr.in from IP |
| `services.backlight` | brightnessctl default |
| `services.keyboard` | compositor |
| `services.budsMac` / `budsName` | Super+B off |
| `appearance.fontUi` | JetBrains Mono |
| `appearance.fontJp` | Noto Sans CJK JP |
| `appearance.fontIcons` | Symbols Nerd Font |
| `appearance.fontPx` | 13 |
| `screens.gamma` | hyprsunset (Hyprland) |

Last palette: `~/.local/state/tanjun/state.json`.

**From wall** builds a palette from the current wallpaper. **pick** sets the file and runs From wall. **presets**: Monochrome, Obsidian, Gray, Deep Blue, Emerald, Golden Amber, Fiery Sunset, Rose Pink, Mocha, Macchiato.

Fonts: Settings. Kitty keeps its own file.

## Tree

```
compositors/
  hyprland/              lua
    hyprland.lua         stub in ~/.config/hypr loads this
    hypridle.conf
    modules/
    themes/
    scripts/
  niri/                  kdl
    config.kdl           stub in ~/.config/niri includes this
    config/
    scripts/
shell/                   → ~/.config/quickshell
  shell.qml
  modules/
  services/
  pam/
  themes/
  scripts/
config.example.json
scripts/setup.sh
scripts/shots.sh
scripts/hyprland.conf.example
```

See `TODO.md`. Current: **v3.4**.
