# Config

Pins live in `~/.config/tanjun/config.json`. Copy [config.example.json](../config.example.json) to start. Settings writes the same file; `reset` in the panel returns rice defaults.

| Pin | |
|-----|--|
| `clock.zones` | Extra clocks (`id` IANA, `label` on the bar) |
| `services.weatherCity` | Open-Meteo city |
| `services.budsMac` | Super+B device |
| `appearance.fontPx` | UI size |
| `appearance.fontUi` / `fontMono` | Families from `fc-list` |
| `appearance.style` | `chrome` (default) or `minimal` |
| `appearance.motion` | `quiet` (default), `instant`, `snappy`, or `soft` |
| `appearance.motionSpeed` | Animation speed in percent, 50–200 (default 100) |

Screens live in Settings → screen: `FIRST` is the laptop panel, `SECOND` the external output, `EXTEND` both. If `SECOND` is active and the external output is unplugged, the shell turns the laptop panel back on for the rest of the session; the saved compositor pin is kept, so plugging the external back in restores `SECOND` on the next start.

Color lives in Settings → Color and in the System drawer.

Style lives in Settings → Style. `chrome` marks the bar with ticks, pips, and accent borders; `minimal` drops to quiet 1px hairlines. Palettes are untouched by either.

Animation has four presets and a demo strip under them that replays the current preset, so the speed of a popout, a panel and a toast is visible before you commit to it.

Named skins are JSON under `shell/themes/` (Monochrome, Obsidian, Gray, Deep Blue, Emerald, Golden Amber, Fiery Sunset, Rose Pink, Mocha, Macchiato). **From wall** samples the current wallpaper. **Pull colors** retints when you pick a paper; **keep palette** changes only the wallpaper, so a new paper cannot jump the rice.

Wallpaper is still or video. The picker walks directories; rice papers live next to the compositor assets.
