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

-- Centre zoom with a slight overshoot, like the picom showcase animations
hl.curve("pop", { type = "spring", mass = 1, stiffness = 238.1191, dampening = 20 })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4,   spring = "pop", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3,   spring = "pop", style = "popin 80%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.5, spring = "pop", style = "fade" })

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
