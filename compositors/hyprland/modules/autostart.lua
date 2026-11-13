---@module 'hl'

hl.on("hyprland.start", function()
    hl.exec_cmd("python3 ~/.local/share/tanjun/shell/scripts/tanjun-paint.py restore & quickshell & hyprsunset & hypridle")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
