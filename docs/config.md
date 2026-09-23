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

Color lives in Settings → Color and in the System drawer.

Named skins are JSON under `shell/themes/` (Monochrome, Obsidian, Gray, Deep Blue, Emerald, Golden Amber, Fiery Sunset, Rose Pink, Mocha, Macchiato). **From wall** samples the current wallpaper. **Pull colors** retints when you pick a paper; **keep palette** changes only the wallpaper, so a new paper cannot jump the rice.

Wallpaper is still or video. The picker walks directories; rice papers live next to the compositor assets.
