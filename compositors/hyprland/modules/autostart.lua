---@module 'hl'

hl.on("hyprland.start", function()
    -- SDDM starts Hyprland as a process; systemd never reaches graphical-session
    -- without this, so xdg-desktop-portal (Zoom share, file pickers) stays dead.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
    hl.exec_cmd("systemctl --user start nixos-fake-graphical-session.target")
    hl.exec_cmd("python3 ~/.local/share/tanjun/shell/scripts/tanjun-paint.py restore & QT_QUICK_BACKEND=software quickshell & hyprsunset")
    hl.exec_cmd('gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic"')
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")
    hl.exec_cmd("hyprctl setcursor rose-pine-hyprcursor 24")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
