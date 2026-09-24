# Optional system-side defaults when Tanjun is the session shell.
# User session links and compositor stubs live in the Home Manager module.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.tanjun;
in
{
  options.programs.tanjun.enable = lib.mkEnableOption "system packages commonly used with Tanjun";

  config = lib.mkIf cfg.enable {
    programs.hyprland.enable = lib.mkDefault true;

    xdg.portal = {
      enable = lib.mkDefault true;
      extraPortals = lib.mkDefault [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-hyprland
      ];
    };

    security.rtkit.enable = lib.mkDefault true;
    services.power-profiles-daemon.enable = lib.mkDefault true;
  };
}
