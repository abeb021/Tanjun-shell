---@module 'hl'
local src = debug.getinfo(1, "S").source:sub(2)
local hyprland = src:match("(.*/)") or "./"
local root = hyprland:gsub("compositors/hyprland/?$", ""):gsub("hyprland/?$", "")
root = root:gsub("/$", "")
return {
    root = root,
    hyprland = hyprland,
    shell = root .. "/shell",
}
