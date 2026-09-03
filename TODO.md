# Tanjun — TODO

単純. One process. Frame off.

Current: **v2.2**

## v1.0 — host (shipping)

- [x] Quickshell host + quiet bar, frame off (JetBrains, 1px, 単 seal)
- [x] Popouts from the glyph; 単 menu hangs off the seal (not a right System sidebar)
- [x] Launcher: empty query is clock / weather / track labels, then app search
- [x] Notifications + do-not-disturb + volume / backlight OSD
- [x] Color: nine named palettes
- [x] Workspaces: numbers / dots on the bar
- [x] Escape closes menus

## v1.1 — hands

Super+A / Super+V and the audio popout, no kitty.

- [x] Clipboard: cliphist images, not text-only
- [x] Launcher: arrows + highlight, Enter launches the selection
- [x] Mixer: per-app streams, not master-only



## v1.2 — overview

- [x] Super+Tab overview with live window previews



## v1.3 — summon

Panels from the keyboard, not only the 16px glyph.

- [x] IPC + binds for audio, network, calendar, battery, notify, 単
- [x] Finish widget chords (scroll / right / middle) where the verb is obvious
- [x] Bind 単 and DND; finish `scripts/install-hypr.sh`



## v1.4 — system

- [x] Real left System sidebar (not the 単 popout)
- [x] Session row: lock, logout, reboot, sleep
- [x] Mixer: mic / default source, not sink-only
- [x] Motion tokens, morphing popouts



## v1.5 — config

Sparse overlay. Defaults in the shell. Pin only this machine.

- [x] `~/.config/tanjun/config.json` via JsonAdapter; omit = auto
- [x] Nested pins: clock zones, weather, backlight, keyboard, lock, theme hook
- [x] Palette last-used in `~/.local/state/tanjun/`; vanilla hypr snippet



## v1.6 — launcher

- [x] Rest card: weather card, art + transport, not four labels
- [x] Prefixes: `=` calc, `;` clipboard, `?` web, `/` act, `@` music



## v1.7 — system

Host facts and a real player in the left System drawer.

- [x] RAM + CPU
- [x] Running processes
- [x] Internet speed
- [x] Distro, kernel, username
- [x] Audio player with art preview (not a one-line label)

## v1.8 — color

- [x] Theme singleton paints kitty / hypr / lock / wallpaper; drop the old switcher script
- [x] Wallpaper-driven accent **plus a lock** so the palette cannot jump
- [x] Notification actions, not dismiss-only
- [x] Wallpaper picker; choosing a file paints it and runs From wall

## v1.9 — polish

No new surfaces. Tighten what shipped.

- [x] Motion, layout, and poll cost
- [x] Visual consistency across bar, popouts, drawer
- [x] Dead paths, leftover jank

## v2.0 — settings

A settings surface, not more bar polish. Summon it; live pins in `config.json`.

- [x] In-shell settings panel (rail + pages), IPC / Super+Ctrl+, / 単
- [x] Font picker: UI, Japanese, icons; size; fc-list
- [x] Clock, weather, session lock, backlight / keyboard
- [x] Color page: From wall + named presets with swatches (same Theme singleton)
- [x] Lookup: search box, Ctrl+K, jump across pages

## v2.1 — face

単純. Unmix the cloned cards. Same rice (frame off, 1px, JetBrains, 単). No new look, no second skin system.

- [x] One recipe per job: popout from the glyph, launcher rest card, settings panel, drawer strip — stop cloning the same accent-bordered rect
- [x] Rest card is one object: clock, weather, track. Not boxes inside boxes. Prefixes stay a quiet legend
- [x] Motion from the glyph you touched, not generic scale from the corner
- [x] OSD and toasts speak the same language. No leftover bars

## v2.2 — desktop

One clone. Hyprland and the shell ship together. Screen is a settings page.

- [x] Compositor in `hyprland/` (one module per concern); Quickshell in `shell/`. `scripts/setup.sh` plants XDG links on any Arch + Hyprland
- [x] Screen page: output, mode, scale, gamma (hyprsunset). Mode/scale persist in `~/.config/hypr/monitors.lua`

