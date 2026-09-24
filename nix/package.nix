{
  lib,
  quickshell,
  writeShellScriptBin,
}:
writeShellScriptBin "tanjun-quickshell" ''
  export QT_QUICK_BACKEND=software
  qs="''${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
  if [ ! -d "$qs" ]; then
    echo "tanjun-quickshell: no quickshell config at $qs (enable programs.tanjun)" >&2
    exit 1
  fi
  exec ${lib.getExe quickshell} -p "$qs"
''
