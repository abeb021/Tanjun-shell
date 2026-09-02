# Tanjun 単純

Frame off. Quiet bar. One process.

Tanjun is the desktop shell for this Hyprland machine: bar, popouts, left System drawer, launcher, notifications, OSD, clipboard, and overview in a single Quickshell process. Hyprland stays compositor. Summon a panel with IPC; do not spawn a new process.

単純 means simple in structure, unmixed. **単** is the seal.

This is not a general-purpose distro shell. It is built against how this laptop sits: eDP-1 @ 1.2, Intel backlight, BAT0, `us,ru`, Moscow + Melbourne, named palettes (not wallpaper-generated color).

## Surfaces

| Surface | What it is |
| --- | --- |
| Bar | Flush to the top. 単, numbered desks, clock, EN/RU, a few glyphs, tray. |
| Popouts | Grow from the glyph you touched: calendar, mixer, wifi, notifications, battery. |
| System | Left drawer from 単 or Super+Ctrl+S. Media, sink + mic, backlight, battery, net, DND, session, palettes. |
| Launcher | Super+A. Empty query is clock / weather / track, then `.desktop` search. |
| Clipboard | Super+V. cliphist, including images. |
| Overview | Super+Tab. Live window previews, desks 1–10. |
| Toasts + OSD | Notifications and volume / backlight. No dim behind menus. |

Widgets are verbs. Left click opens the panel. Scroll, right, and middle do the obvious job on that glyph (volume, mute, TZ, DND, brightness, …).

## Run

Needs [Quickshell](https://quickshell.outfoxxed.me) and Hyprland already on the machine.

```
killall waybar swaync 2>/dev/null
quickshell -p ~/Programming/Tanjun-shell
```

Wire autostart and binds:

```
bash ~/Programming/Tanjun-shell/scripts/install-hypr.sh
```

Reload the session: **Super+Shift+R**.

State lives in `~/.config/tanjun/state.json` (palette kind + name). Palettes are `themes/dark/*.json` and `themes/white/*.json`.

## Hands

Compositor binds stay in Hyprland. The shell only owns what it draws.

| Bind | Action |
| --- | --- |
| Super+A | Launcher |
| Super+V | Clipboard |
| Super+Tab | Overview |
| Super+Ctrl+A | Mixer |
| Super+Ctrl+W | Network |
| Super+Ctrl+C | Calendar |
| Super+Ctrl+B | Battery |
| Super+Ctrl+N | Notifications |
| Super+Ctrl+S | System drawer |
| Super+Ctrl+D | Do not disturb |
| Super+L | Lock (`hyprlock`) |
| Super+1 … 0 | Desks |
| Escape | Close the open surface |

Bar chords worth knowing: scroll audio = volume, right-click = mute; scroll clock = timezone; middle-click clock = Moscow; right-click notify = DND; scroll battery = backlight; right-click a desk number = move the focused window there.

## IPC

Target `tanjun`. Same verbs as the binds:

```
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleLauncher
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleSidebar
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleAudio
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleNetwork
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleCalendar
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleBattery
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleNotify
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleClipboard
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleOverview
quickshell ipc -p ~/Programming/Tanjun-shell call tanjun toggleDnd
```

## Palettes

Nine named looks, switched together. Pick from the System drawer. Wallpaper still follows the name via the existing switcher until the shell paints kitty / hypr / lock itself.

Dark: Monochrome, Obsidian, Gray, Deep Blue, Emerald, Golden Amber, Fiery Sunset, Rose Pink.

White: Mocha, Macchiato.

Face: JetBrains Mono, 1px radius, Nerd Fonts, 単.

## Tree

```
shell.qml              host + IPC
modules/bar            quiet strip + buttons
modules/popouts        panels from the glyph
modules/sidebar        left System
modules/launcher       rest card, then search
modules/clipboard      cliphist
modules/overview       Super+Tab
modules/notifs         toasts
modules/osd            volume / backlight
services/              singletons (theme, audio, net, motion, …)
themes/                named palettes
scripts/install-hypr.sh
```

Next work is in `TODO.md`. Current: **v1.4**.
