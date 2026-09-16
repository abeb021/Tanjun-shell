# TODO

Current: **v2.7**

## v1.0 — bar

- [x] Quickshell bar (JetBrains, 1px, 単)
- [x] Popouts from bar icons; System from 単
- [x] Launcher: clock / weather / track, then app search
- [x] Notifications, DND, volume / backlight OSD
- [x] Nine named palettes
- [x] Workspaces on the bar
- [x] Escape closes menus

## v1.1

- [x] Clipboard: cliphist images
- [x] Launcher: arrows, Enter
- [x] Mixer: per-app streams

## v1.2 — overview

- [x] Super+Tab, live window previews (Hyprland)

## v1.3 — ipc

- [x] Super+Ctrl+… for audio, network, calendar, battery, notify, System
- [x] Scroll / right / middle on bar icons
- [x] DND bind; `scripts/setup.sh`

## v1.4 — system

- [x] Left System drawer
- [x] Lock, logout, reboot, sleep
- [x] Mic in the mixer
- [x] Popout motion

## v1.5 — config

- [x] `~/.config/tanjun/config.json`; omit = default
- [x] Clock zones, weather, backlight, keyboard, lock, theme
- [x] Last palette in `~/.local/state/tanjun/`

## v1.6 — launcher

- [x] Rest card: weather, art, transport
- [x] Prefixes: `=` calc, `;` clipboard, `?` web, `/` act, `@` music

## v1.7 — system

- [x] RAM, CPU, processes, net speed
- [x] Distro, kernel, user
- [x] Player with art

## v1.8 — color

- [x] Theme paints kitty / compositor / lock / wallpaper
- [x] From wall + lock so the palette stays
- [x] Notification actions
- [x] Wallpaper picker

## v1.9

- [x] Motion and poll cost
- [x] Same look on bar, popouts, drawer
- [x] Dead paths

## v2.0 — settings

- [x] Settings panel, Super+Ctrl+,
- [x] Fonts: UI, Japanese, icons, size
- [x] Clock, weather, lock, backlight, keyboard
- [x] Color: From wall + presets
- [x] Search, Ctrl+K

## v2.1

- [x] Popout / rest card / settings / drawer each have their own layout
- [x] Rest card: clock, weather, track
- [x] Popouts grow from the icon
- [x] OSD and toasts match

## v2.2

- [x] `hyprland/` + `shell/`; `scripts/setup.sh`
- [x] Settings → screen: output, mode, scale, gamma

## v2.3 — lock

- [x] Lock in Quickshell (wallpaper, clock, 単, password, fingerprint)
- [x] Super+L, idle, sleep

## v2.4 — compositors

- [x] `compositors/hyprland/` and `compositors/niri/`
- [x] niri: binds, autostart, idle, screens, wallpaper
- [x] setup picker; `--hyprland` / `--niri`

## v2.5 — niri menus

- [x] Popouts and System: click-away + card overlay; Escape closes
- [x] niri IPC `--any-display`; wallpaper in overview backdrop

## v2.6

- [x] Right-click tray icons for app actions
- [x] Mouse wheel opens the app list and moves the selection
- [x] Bar clicks switch desks (lua dispatch)
- [x] Widgets call `Compositor` only. Hyprland and niri each implement that API in `shell/services/comp/`. No `if niri` in the bar, launcher, or settings.
- [x] `bash tests/run.sh` — contract checks; score is success

## v2.7 — mixer

- [x] Mixer lists sinks and sources; click picks the device
