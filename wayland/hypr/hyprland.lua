-- Hyprland session, ported from bspwmrc. Keybinds live in binds.lua.
-- Static env comes from /etc/environment (pam_env); only dynamic vars are set here.

local preset = require("preset")
local scripts = os.getenv("HOME") .. "/Documents/scripts"

------------------
---- MONITORS ----
------------------

-- DRM names differ from xrandr: DisplayPort-1 = DP-2, DisplayPort-0 = DP-1, HDMI-A-0 = HDMI-A-1
hl.monitor({ output = "DP-2",     mode = "2560x1440@170", position = "0x0",       scale = 1 })
hl.monitor({ output = "DP-1",     mode = "1920x1080@144", position = "auto-left", scale = 1, transform = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60",  position = "auto-up",   scale = 1 })
hl.monitor({ output = "",         mode = "preferred",     position = "auto",      scale = 1 })

-- Workspaces 1-5 primary, 6-7 left, 8-9 top (fall back to the focused monitor when absent)
for i = 1, 9 do
    local output = (i <= 5 and "DP-2") or (i <= 7 and "DP-1") or "HDMI-A-1"
    hl.workspace_rule({ workspace = tostring(i), monitor = output, default = (i == 1 or i == 6 or i == 8) })
end

-----------------------------
---- SESSION ENVIRONMENT ----
-----------------------------

-- Same dynamic var xinitrc sets for the X session
local gpg = io.popen("gpgconf --list-dirs agent-ssh-socket 2>/dev/null")
if gpg then
    local sock = gpg:read("*l")
    gpg:close()
    if sock and sock ~= "" then hl.env("SSH_AUTH_SOCK", sock) end
end

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- Hand the whole session env to systemd --user and D-Bus, like xinitrc does
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")

    hl.exec_cmd("hyprpaper")
    hl.exec_cmd(scripts .. "/wayland/wallpaper.sh")
    hl.exec_cmd("waybar")
    hl.exec_cmd("pgrep -x dunst >/dev/null || dunst")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("pgrep -x steam >/dev/null || steam -silent")
    hl.exec_cmd("pgrep -x easyeffects >/dev/null || easyeffects --service-mode --hide-window")
    hl.exec_cmd("pgrep -x udiskie >/dev/null || udiskie --smart-tray")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in     = 3,
        gaps_out    = 5,
        border_size = 1,
        col = {
            active_border   = preset.rgb(preset.BORDER_FOCUSED),
            inactive_border = preset.rgb(preset.BORDER_NORMAL),
        },
        layout        = "dwindle",
        allow_tearing = true,
    },

    decoration = {
        rounding = 0,
        shadow   = { enabled = false },
        blur     = { enabled = true, size = 4, passes = 2 },
    },

    animations = { enabled = true },

    dwindle = {
        preserve_split = true, -- needed for togglesplit / preselect
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        vrr                     = 2, -- fullscreen only
    },

    cursor = {
        warp_on_change_workspace = 1, -- replaces move_pointer_on_key.sh; keyboard focus already warps
    },
})

-- Ported from picom.conf's animations (same curves and durations).
-- Speeds are in 100ms units; anything not listed inherits "global".
hl.curve("overshoot", { type = "bezier", points = { {0.34, 1.36}, {0.64, 1} } })
hl.curve("easeOut",   { type = "bezier", points = { {0.22, 1},    {0.36, 1} } })
hl.curve("easeIn",    { type = "bezier", points = { {0.55, 0},    {1, 0.45} } })
hl.animation({ leaf = "global",        enabled = true, speed = 3,   bezier = "easeOut" })
-- Open: zoom out of the centre from 50% with overshoot; close: back into the centre
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 3.2, bezier = "overshoot", style = "popin 50%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.8, bezier = "easeIn",    style = "popin 60%" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 2.8, bezier = "easeOut" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.8, bezier = "easeOut" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.8, bezier = "easeIn" })
-- Workspace switch: spring fade
hl.curve("pop", { type = "spring", mass = 1, stiffness = 238.1191, dampening = 20 })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 2,   spring = "pop",     style = "fade" })
-- Layers (rofi, notifications): quick appear from 96%
hl.animation({ leaf = "layersIn",      enabled = true, speed = 2,   bezier = "easeOut", style = "popin 96%" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.2, bezier = "easeIn",  style = "popin 97%" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 2,   bezier = "easeOut" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.2, bezier = "easeIn" })

---------------
---- INPUT ----
---------------

-- Mirrors /etc/X11/xorg.conf.d/00-keyboard.conf and 90-libinput.conf
hl.config({
    input = {
        kb_layout     = "us,latam",
        kb_model      = "pc105+inet",
        kb_options    = "caps:escape,grp:alt_space_toggle",
        repeat_delay  = 400,
        repeat_rate   = 100,
        sensitivity   = -0.3,
        accel_profile = "flat",
        follow_mouse  = 1,
    },
})

---------------
---- RULES ----
---------------

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "float-tools",
    match = { class = "(?i).*(pwvucontrol|blueman-manager|lact).*" },
    float = true,
})

hl.window_rule({
    name  = "floating-kitty",
    match = { class = "^floating-kitty$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

require("binds")

-- While rofi is open, switch to an empty submap so its own Super+hjkl binds reach it
hl.define_submap("rofi", function()
    hl.bind("F24", hl.dsp.no_op()) -- an empty submap isn't registered
end)
hl.on("layer.opened", function(layer)
    if layer and layer.namespace == "rofi" then hl.dispatch(hl.dsp.submap("rofi")) end
end)
hl.on("layer.closed", function(layer)
    if layer and layer.namespace == "rofi" then hl.dispatch(hl.dsp.submap("reset")) end
end)
