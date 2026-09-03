# Tanjun 単純

Frame off. Quiet bar. One process.

Tanjun is a Hyprland desktop shell: bar, popouts, left System drawer, launcher, notifications, OSD, clipboard, overview, and settings in a single [Quickshell](https://quickshell.outfoxxed.me) process. Hyprland stays compositor. Summon a panel with IPC; do not spawn a new process. Color follows the wallpaper (**From wall**) or a named preset.

単純 means simple in structure, unmixed. **単** is the seal.

## Surfaces


| Surface      | What it is                                                                                              |
| ------------ | ------------------------------------------------------------------------------------------------------- |
| Bar          | Flush to the top. 単, numbered desks, clock, layout, a few glyphs, tray.                                 |
| Popouts      | Grow from the glyph you touched: calendar, mixer, wifi, notifications, battery.                         |
| System       | Left drawer from 単 or Super+Ctrl+S. User / distro / kernel, player with art, CPU, RAM, processes, net speed, mixer, session, From wall / pick / presets. |
| Launcher     | Super+A. Rest card is clock / weather / art + transport. Type to search apps (ranked by use). Down lists every app the same way. Prefixes: `=` calc, `;` clips, `?` web, `/` act, `@` music. |
| Clipboard    | Super+V. cliphist, including images.                                                                    |
| Overview     | Super+Tab. Live window previews, desks 1–10.                                                            |
| Settings     | Super+Ctrl+, . Search (Ctrl+K) jumps pages. Color chips show the palette. Live pins in `config.json`. |
| Toasts + OSD | Notifications and volume / backlight. No dim behind menus.                                              |


Widgets are verbs. Left click opens the panel. Scroll, right, and middle do the obvious job on that glyph (volume, mute, TZ, DND, brightness, …).

## Run

Needs Quickshell and Hyprland.

```
git clone <this-repo> Tanjun-shell
cd Tanjun-shell
killall waybar swaync 2>/dev/null
quickshell -p "$PWD"
```

The file is optional. Defaults live in the shell. Create `~/.config/tanjun/config.json` only for the keys you want to pin. Omit a key and the default stays. Do not copy the whole example — it is a reference, and dumped keys go stale.

Empty / omitted means auto: local timezone, `wttr.in` from IP, default `brightnessctl` device, Hyprland’s main keyboard, `loginctl lock-session`. Last-used palette: `~/.local/state/tanjun/state.json`. Palettes are `themes/dark/*.json` and `themes/white/*.json`.

## Hands

Compositor binds stay in Hyprland. The shell only owns what it draws. Vanilla `hyprland.conf` snippet: `scripts/hyprland.conf.example`. If this machine uses a `~/.config/hypr/hyprland/*.lua` layout, `bash scripts/install-hypr.sh` can patch autostart and binds from the clone path.

Reload the session: **Super+Shift+R**.


| Bind         | Action          |
| ------------ | --------------- |
| Super+A      | Launcher        |
| Super+V      | Clipboard       |
| Super+Tab    | Overview        |
| Super+Ctrl+A | Mixer           |
| Super+Ctrl+W | Network         |
| Super+Ctrl+C | Calendar        |
| Super+Ctrl+B | Battery         |
| Super+Ctrl+N | Notifications   |
| Super+Ctrl+S | System drawer   |
| Super+Ctrl+, | Settings        |
| Ctrl+K       | Search in settings (while open) |
| Super+Ctrl+D | Do not disturb  |
| Super+L      | Lock (see config) |
| Super+1 … 0  | Desks           |
| Escape       | Close the open surface |


Bar chords worth knowing: scroll audio = volume, right-click = mute; scroll clock = timezone; middle-click clock = first zone; right-click notify = DND; scroll battery = backlight; right-click a desk number = move the focused window there.

Launcher prefixes: `=` calc (qalc, else python), `;` cliphist, `?` web, `/` actions (lock, settings, system, …), `@` now-playing + Spotify search. Enter on a calc row copies the result.

## IPC

Target `tanjun`. Same verbs as the binds. `$ROOT` is the clone directory:

```
quickshell ipc -p "$ROOT" call tanjun toggleLauncher
quickshell ipc -p "$ROOT" call tanjun toggleSidebar
quickshell ipc -p "$ROOT" call tanjun toggleAudio
quickshell ipc -p "$ROOT" call tanjun toggleNetwork
quickshell ipc -p "$ROOT" call tanjun toggleCalendar
quickshell ipc -p "$ROOT" call tanjun toggleBattery
quickshell ipc -p "$ROOT" call tanjun toggleNotify
quickshell ipc -p "$ROOT" call tanjun toggleClipboard
quickshell ipc -p "$ROOT" call tanjun toggleSettings
quickshell ipc -p "$ROOT" call tanjun toggleOverview
quickshell ipc -p "$ROOT" call tanjun toggleDnd
```

## Config

`~/.config/tanjun/config.json` — sparse overlay. Nested keys match the surfaces. See `config.example.json` for a small pin, not a full dump.

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


| Key                    | Omit / empty means                    |
| ---------------------- | ------------------------------------- |
| `clock.zones`          | One clock: the system timezone        |
| `clock.twelveHour`     | From the locale                       |
| `services.weatherCity` | `wttr.in` lookup from IP              |
| `services.backlight`   | Default `brightnessctl` device        |
| `services.keyboard`    | Hyprland main keyboard                |
| `session.lock`         | `["loginctl", "lock-session"]`        |
| `appearance.fontUi`    | JetBrains Mono                        |
| `appearance.fontJp`    | Noto Sans CJK JP                      |
| `appearance.fontIcons` | Symbols Nerd Font                     |
| `appearance.fontPx`    | 13                                    |


`session.lock` is an argv list (`["hyprlock"]` if that is your locker). A previous flat `config.json` is rewritten to nested sparse on load.

## From wall

The live look is the wallpaper. Named presets stay as a fallback.

**From wall** samples the current file into a full palette: background, cards, type, accent. Hue stays with the image — an Emerald wall stays teal, a Fiery Sunset stays brown. Pitch-black walls get a small lightness lift so glyphs stay readable; crushed gray is not the fallback. Hyprland borders follow that palette. Click again to resample.

**pick** opens a thumbnail grid (folders in place, chips for the wallpaper dir and Pictures). Choosing a file sets hyprpaper and runs From wall.

**presets** are the nine named looks. A named chip paints kitty, Hyprland, hyprlock, and the matching file under `~/.config/hypr/assets/wallpapers/`.

Dark: Monochrome, Obsidian, Gray, Deep Blue, Emerald, Golden Amber, Fiery Sunset, Rose Pink.

White: Mocha, Macchiato.

Face: JetBrains Mono, 1px radius, Nerd Fonts, 単. Change the three families and the size from settings; that pin stays in-shell (kitty / lock keep their own files).

Toasts carry notification actions, not dismiss-only.

## Tree

```
shell.qml                    host + IPC
config.example.json          sparse pin reference (do not dump)
modules/bar                  quiet strip + bar glyphs
modules/widgets              shared type, chips, sliders, player
modules/popouts              panels from the glyph
modules/sidebar              left System + wallpaper picker
modules/launcher             rest card, then search
modules/clipboard            cliphist
modules/overview             Super+Tab
modules/settings             rail + pages (type, clock, weather, session, devices, color)
modules/notifs               toasts
modules/osd                  volume / backlight
services/                    singletons (config, theme, audio, net, motion, …)
themes/                      named palettes
scripts/tanjun-paint.py      kitty / hypr / lock / wallpaper
scripts/install-hypr.sh      optional lua-hypr patcher
scripts/hyprland.conf.example
```

Next work is in `TODO.md`. Current: **v2.0**.
