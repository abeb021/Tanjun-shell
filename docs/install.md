# Install

```bash
git clone https://github.com/abeb021/Tanjun-shell.git
cd Tanjun-shell
bash scripts/setup.sh --hyprland   # or --niri
```

`setup.sh` links `shell/` to `~/.config/quickshell`, writes compositor autostart and binds, and copies lock PAM to `~/.config/tanjun/pam` (mode 600). That PAM directory is trusted like sudoers: group- or world-writable files are refused.

Needs [Quickshell](https://quickshell.outfoxxed.me) on `PATH`. Compositor rice lives next to the shell, not inside it:

```
compositors/hyprland/   lua, one concern per modules/ file
compositors/niri/       kdl
shell/                  Quickshell (bar, launcher, lock, settings, …)
scripts/setup.sh
```

Restart the compositor after setup, or start Quickshell yourself:

```bash
quickshell -p ~/.config/quickshell
```
