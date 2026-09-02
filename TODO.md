# Tanjun — TODO

単純. One process. Frame off.

Current: **v1.6**

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
- [x] Prefixes: `=` calc, `;` clipboard, `?` web, `/` actions, `@` music



## v1.7 — system

Host facts and a real player in the left System drawer.

- [ ] RAM + CPU
- [ ] Running processes
- [ ] Internet speed
- [ ] Distro, kernel, username
- [ ] Audio player with art preview (not a one-line label)

## v1.8 — paint

- [ ] Theme singleton paints kitty / hypr / lock / wallpaper; drop the old switcher script
- [ ] Notification actions, not dismiss-only

## v1.9 — color lock

- [ ] Wallpaper-driven accent **plus a lock** so the palette cannot jump

## v1.10 — type

- [ ] Font picker inside the shell