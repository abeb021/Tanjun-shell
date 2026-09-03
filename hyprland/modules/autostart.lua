---@module 'hl'

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper --config ~/.config/hypr/hyprpaper.conf & quickshell & hypridle & hyprsunset")
    hl.exec_cmd('gsettings set org.gnome.desktop.interface gtk-theme "Dracula"')
    hl.exec_cmd('gsettings set org.gnome.desktop.wm.preferences theme "Dracula"')
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
end)
