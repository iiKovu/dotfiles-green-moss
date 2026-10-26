-- Reads the active color preset (~/.config/themes/current/preset.sh) so the
-- Hyprland session follows the same presets as bspwm. theme.sh reloads
-- Hyprland after switching, which re-reads this file.

local home = os.getenv("HOME")
local preset = {}

local f = io.open(home .. "/.config/themes/current/preset.sh")
if f then
    for line in f:lines() do
        local key, value = line:match('^([%w_]+)="?(.-)"?$')
        if key then
            preset[key] = (value:gsub("%$HOME", home))
        end
    end
    f:close()
end

-- "#3D3D3D" -> "rgb(3D3D3D)"
function preset.rgb(hex)
    return "rgb(" .. (hex or "#888888"):gsub("#", "") .. ")"
end

return preset
