---@module 'hl'

local src = debug.getinfo(1, "S").source:sub(2)
local here = src:match("(.*/)") or "./"
local cfg = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")

package.path = here .. "?.lua;" .. here .. "?/init.lua;" .. cfg .. "/hypr/?.lua;" .. cfg .. "/hypr/?/init.lua;" .. package.path

-- paint still writes hyprland.themes.* into ~/.config; clone palettes live at themes/
local function loadTheme(name)
    if type(name) ~= "string" then
        return nil
    end
    local names = { name:gsub("^hyprland%.", ""), name }
    for _, n in ipairs(names) do
        local ok, theme = pcall(require, n)
        if ok then
            return theme
        end
    end
    return nil
end

local ok, name = pcall(dofile, cfg .. "/hypr/hyprland/active_theme.lua")
local theme = ok and loadTheme(name)
if not theme then
    theme = require("themes.dark.monochrome")
end
package.loaded["hyprland.theme"] = theme

local pin = cfg .. "/hypr/monitors.lua"
local pf = io.open(pin, "r")
if pf then
    pf:close()
    dofile(pin)
end

require("modules.env")
require("modules.general")
require("modules.input")
require("modules.decoration")
require("modules.animations")
require("modules.workspace")
require("modules.binds")
require("modules.misc")
require("modules.rules")
require("modules.autostart")
require("modules.layouts")
