-- Compat stub. Rice lives in compositors/hyprland/. Re-run scripts/setup.sh to point the XDG stub there directly.
local src = debug.getinfo(1, "S").source:sub(2)
local here = src:match("(.*/)") or "./"
dofile(here .. "../compositors/hyprland/hyprland.lua")
