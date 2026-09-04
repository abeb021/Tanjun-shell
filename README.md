# Tanjun 単純

Frame off. Quiet bar. One process.

Tanjun is a Wayland shell: compositor rice and the Quickshell host ship in this clone. Hyprland and niri are both supported. Bar, popouts, left System drawer, launcher, notifications, OSD, clipboard, overview, settings, and lock run in one [Quickshell](https://quickshell.outfoxxed.me) process. Summon a panel with IPC; do not spawn a new process. Color follows the wallpaper (**From wall**) or a named preset.

単純 means simple in structure, unmixed. **単** is the seal.

![Bar on an empty desk](docs/desktop.webp)

## Surfaces

![Launcher rest card](docs/launcher.webp)

![Settings](docs/settings.webp)

![Calendar popout](docs/calendar.webp)

![System drawer](docs/system.webp)


| Surface      | What it is                                                                                              |
| ------------ | ------------------------------------------------------------------------------------------------------- |
| Bar          | Flush to the top. 単, numbered desks, clock, layout, a few glyphs, tray.                                 |
| Popouts      | Grow from the glyph you touched: calendar, mixer, wifi, notifications, battery.                         |
| System       | Left drawer from 単 or Super+Ctrl+S. User / distro / kernel, player with art, CPU, RAM, processes, net speed, mixer, session, From wall / pick / presets. |
| Launcher     | Super+A. Rest card is clock / weather / art + transport. Type to search apps (ranked by use). Down lists every app the same way. Prefixes: `=` calc, `;` clips, `?` web, `/` act, `@` music. |
| Clipboard    | Super+V. cliphist, including images.                                                                    |
| Overview     | Super+Tab. On Hyprland: live window previews, desks 1–10. On niri: the compositor overview. |
| Settings     | Super+Ctrl+, . Search (Ctrl+K) jumps pages. Screen: output, mode, scale, gamma. Color chips show the palette. Live pins in `config.json`. |
| Lock         | Super+L. Wallpaper, clock, password, fingerprint. Same rice. Idle and sleep go through this lock.                                        |
| Toasts + OSD | Notifications and volume / backlight. No dim behind menus.                                                                              |


Widgets are verbs. Left click opens the panel. Scroll, right, and middle do the obvious job on that glyph (volume, mute, TZ, DND, brightness, …).

## Run

Needs Arch Linux, Quickshell, and a compositor (Hyprland or niri). One command from the clone (any path):

```
git clone <this-repo> Tanjun-shell
cd Tanjun-shell
bash scripts/setup.sh
```

Detects the current session and opens a compositor picker (単, j/k, enter). Pass `--hyprland` or `--niri` to skip it.

It installs missing packages (`pacman`, AUR helper if a name is not in extra), plants XDG links, and writes a compositor stub with no machine path. It does not kill running processes. Super+Shift+R (or a new session) picks it up. The git tree can live anywhere; the system always looks here:

- `~/.local/share/tanjun` → this clone
- `~/.config/quickshell` → `shell/` (so `quickshell` needs no `-p`)
- Hyprland: `~/.config/hypr/hyprland.lua` → stub that loads `compositors/hyprland/`
- niri: `~/.config/niri/config.kdl` → stub that includes `compositors/niri/`

Outputs stay auto until you pin them in Settings → screen (`~/.config/hypr/monitors.lua` or `~/.config/niri/output.kdl`).

Pins stay separate: `~/.config/tanjun/config.json`. Super+Shift+R reloads both.

The Tanjun config file is optional. Defaults live in the shell. Create `~/.config/tanjun/config.json` only for the keys you want to pin. Omit a key and the default stays. Do not copy the whole example — it is a reference, and dumped keys go stale.

Empty / omitted means auto: local timezone, `wttr.in` from IP, default `brightnessctl` device, compositor keyboard, Tanjun lock. Last-used palette: `~/.local/state/tanjun/state.json`. Palettes are `shell/themes/dark/*.json` and `shell/themes/white/*.json`.

## Hands

Compositor binds live in `compositors/hyprland/modules/binds.lua` and `compositors/niri/config/keybinds.kdl`. `bash scripts/setup.sh` plants the XDG links and the compositor stub. Vanilla hyprlang fallback: `scripts/hyprland.conf.example`.

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
| Super+L      | Lock            |
| Super+1 … 0  | Desks           |
| Escape       | Close the open surface |


Bar chords worth knowing: scroll audio = volume, right-click = mute; scroll clock = timezone; middle-click clock = first zone; right-click notify = DND; scroll battery = backlight; right-click a desk number = move the focused window there.

Launcher prefixes: `=` calc (qalc, else python), `;` cliphist, `?` web, `/` actions (lock, settings, system, …), `@` now-playing + Spotify search. Enter on a calc row copies the result.

## IPC

Target `tanjun`. Same verbs as the binds. After install, no clone path:

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
| `services.keyboard`    | Compositor keyboard                   |
| `appearance.fontUi`    | JetBrains Mono                        |
| `appearance.fontJp`    | Noto Sans CJK JP                      |
| `appearance.fontIcons` | Symbols Nerd Font                     |
| `appearance.fontPx`    | 13                                    |
| `screens.gamma`        | hyprsunset as-is (Hyprland only)      |


A previous flat `config.json` is rewritten to nested sparse on load.

## From wall

The live look is the wallpaper. Named presets stay as a fallback.

**From wall** samples the current file into a full palette: background, cards, type, accent. Hue stays with the image — an Emerald wall stays teal, a Fiery Sunset stays brown. Pitch-black walls get a small lightness lift so glyphs stay readable; crushed gray is not the fallback. Hyprland borders follow that palette. Click again to resample.

**pick** opens a thumbnail grid (folders in place, chips for the wallpaper dir and Pictures). Choosing a file sets the wallpaper daemon (hyprpaper or swaybg) and runs From wall.

**presets** are the nine named looks. A named chip paints kitty, the live compositor, and the matching file under `~/.config/hypr/assets/wallpapers/`.

Dark: Monochrome, Obsidian, Gray, Deep Blue, Emerald, Golden Amber, Fiery Sunset, Rose Pink.

White: Mocha, Macchiato.

Face: JetBrains Mono, 1px radius, Nerd Fonts, 単. Change the three families and the size from settings; that pin stays in-shell (kitty keeps its own file).

Toasts carry notification actions, not dismiss-only.

## Tree

```
compositors/
  hyprland/              lua rice. one concern per module
    hyprland.lua         entry. setup writes a stub in ~/.config/hypr
    hypridle.conf        idle → lock / dpms / sleep
    modules/             binds, autostart, rules, rice
    themes/              compositor palettes
    scripts/             reload the host
  niri/                  kdl rice
    config.kdl           entry. setup writes a stub in ~/.config/niri
    config/              binds, autostart, rules, rice
    scripts/             idle + reload the host
shell/                   Quickshell host → ~/.config/quickshell
  shell.qml              host + IPC
  modules/               bar, popouts, drawer, launcher, settings, lock
  services/              singletons (config, compositor, theme, screens, lock, …)
  pam/                   lock auth (password, fingerprint)
  themes/                named palettes (json)
  scripts/               paint / calc / clip / host
config.example.json      sparse pin reference (do not dump)
scripts/setup.sh         attach shell + chosen compositor
scripts/shots.sh         grim + magick → docs/*.webp (README)
scripts/hyprland.conf.example
```

Next work is in `TODO.md`. Current: **v2.4**.
