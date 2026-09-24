{ self, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.tanjun;
  home = config.home.homeDirectory;
  dataLink = "${home}/.local/share/tanjun";
  qsLink = "${config.xdg.configHome}/quickshell";
  stateDir = "${home}/.local/state/tanjun";
  stateFile = "${stateDir}/state.json";
in
{
  options.programs.tanjun = {
    enable = lib.mkEnableOption "Tanjun (Quickshell checkout, compositor stub, session links)";

    checkout = lib.mkOption {
      type = lib.types.path;
      default = self.outPath;
      defaultText = lib.literalExpression "tanjun flake source (from inputs.tanjun)";
      example = "/home/you/Programming/Tanjun-shell";
      description = ''
        Tree that contains `shell/` and `compositors/`. Defaults to the Tanjun
        flake source (GitHub pin updates on `nix flake update` + rebuild).

        Override with a local git checkout path for live QML edits without
        rebuilding the home-manager generation.
      '';
    };

    compositor = lib.mkOption {
      type = lib.types.enum [
        "hyprland"
        "niri"
      ];
      default = "hyprland";
      description = "Which compositor stub to write under ~/.config.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "tanjun.packages.<system>.default";
      description = "Wrapped quickshell launcher (QT_QUICK_BACKEND=software).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.activation.tanjunAttach = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      checkout=${lib.escapeShellArg (toString cfg.checkout)}
      if [ ! -d "$checkout/shell" ]; then
        echo "programs.tanjun: missing shell/ under $checkout" >&2
        exit 1
      fi
      run mkdir -p ${lib.escapeShellArg (builtins.dirOf dataLink)} ${lib.escapeShellArg (builtins.dirOf qsLink)}
      run ln -sfn "$checkout" ${lib.escapeShellArg dataLink}
      run ln -sfn "$checkout/shell" ${lib.escapeShellArg qsLink}
      run mkdir -p ${lib.escapeShellArg stateDir}
      if [ ! -f ${lib.escapeShellArg stateFile} ]; then
        printf '%s\n' '{"kind":"dark","name":"monochrome"}' > ${lib.escapeShellArg stateFile}
      fi
      run chmod +x "$checkout"/scripts/*.sh 2>/dev/null || true
      run chmod +x "$checkout"/compositors/hyprland/scripts/*.sh 2>/dev/null || true
      run chmod +x "$checkout"/compositors/niri/scripts/*.sh 2>/dev/null || true
      run chmod +x "$checkout"/shell/scripts/*.sh 2>/dev/null || true
    '';

    xdg.configFile =
      lib.mkMerge [
        (lib.mkIf (cfg.compositor == "hyprland") {
          "hypr/hyprland.lua".text = ''
            -- Tanjun compositor. Managed by Home Manager (programs.tanjun).
            local home = os.getenv("HOME") or ""
            local data = os.getenv("XDG_DATA_HOME") or (home .. "/.local/share")
            dofile(data .. "/tanjun/compositors/hyprland/hyprland.lua")
          '';
        })
        (lib.mkIf (cfg.compositor == "niri") {
          "niri/config.kdl".text = ''
            // Tanjun. Outputs: output.kdl
            include "tanjun/config.kdl"
            include "output.kdl"
          '';
        })
      ];

    home.activation.tanjunHyprTheme = lib.hm.dag.entryAfter [ "tanjunAttach" ] (
      lib.optionalString (cfg.compositor == "hyprland") ''
        theme=${lib.escapeShellArg "${config.xdg.configHome}/hypr/hyprland/active_theme.lua"}
        run mkdir -p ${lib.escapeShellArg "${config.xdg.configHome}/hypr/hyprland/themes/wall"}
        if [ ! -f "$theme" ]; then
          echo 'return "hyprland.themes.dark.monochrome"' > "$theme"
        fi
      ''
    );

    home.activation.tanjunNiri = lib.hm.dag.entryAfter [ "tanjunAttach" ] (
      lib.optionalString (cfg.compositor == "niri") ''
        niri=${lib.escapeShellArg "${config.xdg.configHome}/niri"}
        checkout=${lib.escapeShellArg (toString cfg.checkout)}
        run mkdir -p "$niri"
        run ln -sfn "$checkout/compositors/niri" "$niri/tanjun"
        out=${lib.escapeShellArg "${config.xdg.configHome}/niri/output.kdl"}
        if [ ! -f "$out" ]; then
          echo '// Outputs. Settings → screen writes this file.' > "$out"
        fi
      ''
    );
  };
}
