# TODO

Current: **v3.5**

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
- [x] Clock, weather, backlight, keyboard
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
- [x] `bash tests/run.sh` — qs ipc + config; score is success

## v2.7 — mixer

- [x] Mixer lists sinks and sources; click picks the device

## v2.8 — panel host

- [x] Popout overlay leaves the bar clickable
- [x] Super+Ctrl popouts open on the focused screen, from that glyph
- [x] Click on another output closes the popout
- [x] Mixer lists attached devices (named HDMI, buds), not empty ports or the analog jack

## v2.9 — wall

- [x] Picker takes mp4 / webm; mpvpaper loops muted on both compositors
- [x] Lock uses a still frame; video pauses while locked
- [x] Login restores the last still or video
- [x] Pick a wall with pull colors, or keep the current palette and change only the wallpaper

## v3.0 — host

- [x] Settings, clipboard, and overview use the same overlay host (bar hole, key prime, other-output dismiss)
- [x] Overview talks to `Compositor` only; Super+Tab lists windows on niri too
- [x] Mixer and net lists take arrows / hjkl / Enter
- [x] Polkit dialog lives in the shell
- [x] Idle (dim / lock / DPMS / sleep) lives in the shell
- [x] Mixer hides unplugged ports from PipeWire, not from nicknames

## v3.1 — settings

- [x] Settings card; rail with a mark
- [x] Pages: system, sound, screen, network, bluetooth, type, clock, weather, devices, color
- [x] Scale slider snaps to real stops
- [x] Style page: Tanjun and Panel chrome, apart from palettes
- [x] Chrome on every surface; ticks only on planes (settings, launcher, System, clipboard, polkit)

## v3.2 — harden

- [x] Wi-Fi PSK off argv; PAM faillock; lock before sleep; idle inhibit while media plays
- [x] Backlight / VPN / Host idle polls; overview freeze; Hypr windows gated
- [x] Atomic config/state; wallpaper PIDs; no clobber of a real background file
- [x] OverlayHost for popouts, launcher, System; lazy popouts; no Settings preload
- [x] Settings nav and OSD off the menu bus; Type page; Tanjun wall dir
- [x] Launcher debounce; one clip decode; host `/proc`; buds in config; pollJson tests
- [x] Snapshot `wallDir`; mkdir before config write; clip cache 32MiB; WallPick legacy fallback

## v3.3 — leftover audit

- [x] UiMode exclusive surfaces; TestHooks for poll/hostCaps/catalog
- [x] HostBase compositor contract; idle inhibit from clients and logind
- [x] Palette paint in Wall; settings catalog on SettingsNav
- [x] PAM copy to `~/.config/tanjun/pam` (mode 600, refuse group/world writable)

## v3.4 — test host

- [x] Suite boots its own `qs`; dead QML fails before IPC
- [x] Super+Shift+R waits for `Configuration Loaded`; log in `~/.local/state/tanjun/reload.log`

## v3.5 — speed

- [x] Host: one `--watch` helper while System/settings are open; delta CPU; no Repeater rewrite if the top list is unchanged
- [x] Overview cards keyed by window id; desk ListView; unload Settings/Overview/Clipboard/Launcher after close
- [x] Niri capture + debounce; weather/backlight/clip/audio/launcher/paint/wait-qs cheap paths
- [x] Idle RSS: software scene graph (no Mesa LLVM); seal font; unload launcher; cap notifications

