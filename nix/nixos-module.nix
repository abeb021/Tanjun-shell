# Optional system-side defaults when Tanjun is the session shell.
# User session links and compositor stubs live in the Home Manager module.
{
  config,
  lib,
  pkgs,
  options,
  ...
}:

let
  cfg = config.programs.tanjun;
in
{
  options.programs.tanjun = {
    enable = lib.mkEnableOption "system packages commonly used with Tanjun";

    compositor = lib.mkOption {
      type = lib.types.enum [
        "hyprland"
        "niri"
      ];
      default = "hyprland";
      description = "Compositor to enable system-side defaults for.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        xdg.portal = {
          enable = lib.mkDefault true;
          extraPortals = lib.mkDefault (
            [ pkgs.xdg-desktop-portal-gtk ]
            ++ lib.optional (cfg.compositor == "hyprland") pkgs.xdg-desktop-portal-hyprland
          );
        };

        security.rtkit.enable = lib.mkDefault true;
        services.power-profiles-daemon.enable = lib.mkDefault true;
        services.upower.enable = lib.mkDefault true;

        # Night light on niri is driven through wlr-gamma-control by
        # wl-gammarelay-rs; Hyprland uses hyprsunset.
        environment.systemPackages = lib.optional (cfg.compositor == "niri") pkgs.wl-gammarelay-rs;
      }

      # `programs.niri` is not available on every nixpkgs revision.
      (lib.optionalAttrs (options.programs ? niri) {
        programs.niri.enable = lib.mkDefault (cfg.compositor == "niri");
      })

      {
        programs.hyprland.enable = lib.mkDefault (cfg.compositor == "hyprland");
      }
    ]
  );
}
