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

## NixOS / Home Manager

The repo ships a flake with `homeManagerModules.default` and an optional `nixosModules.default`.

1. Add a flake input:

```nix
tanjun.url = "github:abeb021/Tanjun-shell";
tanjun.inputs.nixpkgs.follows = "nixpkgs";
```

2. Import the Home Manager module:

```nix
{ inputs, ... }:
{
  imports = [ inputs.tanjun.homeManagerModules.default ];
  programs.tanjun = {
    enable = true;
    compositor = "hyprland"; # or "niri"
  };
}
```

`checkout` defaults to the pinned flake source (`nix flake update tanjun` to move versions). For live edits against a git clone:

```nix
programs.tanjun.checkout = "/path/to/Tanjun-shell";
```

On rebuild, Home Manager:

- symlinks `~/.local/share/tanjun` and `~/.config/quickshell` to that checkout
- writes the Hyprland or niri compositor stub under `~/.config`
- installs `tanjun-quickshell` on `PATH` (`QT_QUICK_BACKEND=software`)

System packages (quickshell, cliphist, hypr tools) stay in your NixOS modules. Hyprland autostart in the Tanjun rice still starts Quickshell; you can call `tanjun-quickshell` manually instead.

Compositor integration on NixOS is the same as on Arch: rice lives in the checkout under `compositors/`, not inside the HM module.
