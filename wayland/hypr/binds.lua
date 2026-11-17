local home = os.getenv("HOME")
local scripts = home .. "/Documents/scripts"
local shots = home .. "/Documents/Pictures/screenshots"

local function bind(keys, dsp, opts) hl.bind(keys, dsp, opts) end
local function exec(cmd) return hl.dsp.exec_cmd(cmd) end

-- Hidden windows
local origin = {}
local function hide(w)
    if not w or not w.workspace then return end
    origin[w.address] = w.workspace.id
    hl.dispatch(hl.dsp.window.move({ window = w, workspace = "special:hidden", follow = false }))
end

local function hidden_windows()
    local out = {}
    for _, w in ipairs(hl.get_windows()) do
        if w.workspace and w.workspace.name == "special:hidden" then table.insert(out, w) end
    end
    return out
end

-- Quickshell notch call
local function notch(call, fallback)
    return function()
        local p = io.popen("pgrep -x quickshell")
        local running = p ~= nil and p:read("*a") ~= ""
        if p then p:close() end
        if running then
            hl.exec_cmd("qs ipc call notch " .. call)
        elseif fallback then
            hl.dispatch(fallback)
        end
    end
end

-- WM-independent keys

bind("SUPER + Escape", exec("hyprctl reload"))
bind("SUPER + Return", exec("kitty"))

-- Floating kitty
bind("SUPER + SHIFT + Return", function()
    local term
    for _, w in ipairs(hl.get_windows()) do
        if w.class == "floating-kitty" then term = w break end
    end
    if not term then
        hl.exec_cmd("kitty --class floating-kitty -o initial_window_width=80c -o initial_window_height=20c")
        return
    end
    local current = hl.get_active_workspace()
    if term.workspace and current and term.workspace.id == current.id then
        hide(term)
    else
        origin[term.address] = nil
        hl.dispatch(hl.dsp.window.move({ window = term, workspace = current, follow = false }))
        hl.dispatch(hl.dsp.focus({ window = term }))
    end
end)

bind("SUPER + space",         exec("rofi -show drun"))
bind("SUPER + SHIFT + space", exec("rofi -show run"))
bind("SUPER + z",             exec("rofi-pass"))
bind("SUPER + x",             exec(home .. "/.config/rofi/powermenu/powermenu.sh"))
bind("SUPER + d",             notch("control"))
bind("SUPER + r",             notch("launcher"))
bind("SUPER + e",             exec("kitty -e yazi"))
bind("SUPER + o",             exec("obsidian"))
bind("SUPER + n",             exec("notify-send 'Hey, this is a test' 'This is a test as well'"))
bind("SUPER + period",        exec("rofimoji"))
bind("SUPER + SHIFT + z",     exec("pkill -x waybar; pkill -x quickshell; " .. scripts .. "/wayland/bar.sh"))
bind("SUPER + v",             exec("cliphist list | rofi -dmenu -p clipboard | cliphist decode | wl-copy"))
-- X11-only, kept in sxhkd: SUPER + p Misa assistant (bspc), CTRL + ALT + i fastclick (xdotool)

-- Screenshots
bind("SHIFT + Print", exec("grim \"" .. shots .. "/Fullscreen/$(date +%F_%H-%M-%S)_fullscreen.png\" && notify-send 'Screenshot Taken' 'Fullscreen'"))
bind("SUPER + SHIFT + s", exec("g=$(slurp) && grim -g \"$g\" - | wl-copy --type image/png && notify-send 'Screenshot Taken' 'Area Selection'"))
bind("SUPER + SHIFT + a", exec("g=$(slurp) && sleep 1 && grim -g \"$g\" - | wl-copy --type image/png && notify-send 'Screenshot Taken' 'Area Selection with Timer'"))
bind("SUPER + SHIFT + v", exec(scripts .. "/wayland/screenshot-shadow.sh"))

-- Media
bind("XF86AudioRaiseVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
bind("XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
bind("XF86AudioMute",        exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
bind("XF86AudioPrev",        exec("playerctl -p spotify,%any previous"),   { locked = true })
bind("XF86AudioPlay",        exec("playerctl -p spotify,%any play-pause"), { locked = true })
bind("XF86AudioNext",        exec("playerctl -p spotify,%any next"),       { locked = true })

-- Window management

bind("SUPER + SHIFT + r", exec("hyprctl reload"))
bind("SUPER + w",         hl.dsp.window.close())
bind("SUPER + SHIFT + w", hl.dsp.window.kill())

-- Toggle monocle on the current workspace
local monocle = {}
bind("SUPER + m", function()
    local ws = hl.get_active_workspace()
    if not ws then return end
    if monocle[ws.id] then
        monocle[ws.id]:set_enabled(false)
        monocle[ws.id] = nil
    else
        monocle[ws.id] = hl.workspace_rule({ workspace = tostring(ws.id), layout = "monocle" })
    end
end)

-- Swap the focused window with the biggest tiled one on the workspace
bind("SUPER + g", function()
    local active = hl.get_active_window()
    if not active or not active.workspace then return end
    local biggest, area = nil, 0
    for _, w in ipairs(hl.get_workspace_windows(active.workspace)) do
        local s = w.size or {}
        local a = (s.x or s[1] or 0) * (s.y or s[2] or 0)
        if not w.floating and a > area then biggest, area = w, a end
    end
    if biggest and biggest.address ~= active.address then
        hl.dispatch(hl.dsp.window.swap({ target = "address:" .. biggest.address }))
    end
end)

-- States: tiled / pseudo-tiled / floating / fullscreen
bind("SUPER + t",         hl.dsp.window.float({ action = "disable" }))
bind("SUPER + SHIFT + t", hl.dsp.window.pseudo())
bind("SUPER + s",         hl.dsp.window.float())
bind("SUPER + f",         hl.dsp.window.fullscreen())

-- Flags: hidden, sticky, and unhide function
bind("SUPER + ALT + g", function() hide(hl.get_active_window()) end)
bind("SUPER + ALT + b", hl.dsp.window.pin())
bind("SUPER + ALT + u", function()
    local current = hl.get_active_workspace()
    if not current then return end
    for _, w in ipairs(hidden_windows()) do
        local o = origin[w.address]
        if o == nil or o == current.id then
            origin[w.address] = nil
            hl.dispatch(hl.dsp.window.move({ window = w, workspace = current, follow = false }))
        end
    end
end)

----------------------
---- Focus / Swap ----
----------------------

local dirs = { h = "l", j = "d", k = "u", l = "r" }
for key, dir in pairs(dirs) do
    bind("SUPER + " .. key,         hl.dsp.focus({ direction = dir }), { repeating = true })
    bind("SUPER + SHIFT + " .. key, hl.dsp.window.swap({ direction = dir }), { repeating = true })
end

-- Preselection
local presel
local function clear_presel()
    if presel then hl.dispatch(hl.dsp.window.tag({ tag = "-presel", window = "address:" .. presel })) end
    presel = nil
end
for key, dir in pairs(dirs) do
    bind("SUPER + ALT + " .. key, function()
        local w = hl.get_active_window()
        if not w or w.floating then return end
        clear_presel()
        hl.dispatch(hl.dsp.layout("preselect " .. dir))
        hl.dispatch(hl.dsp.window.tag({ tag = "+presel" }))
        presel = w.address
    end)
end
-- Cancel
bind("SUPER + ALT + space", function()
    hl.dispatch(hl.dsp.layout("preselect x"))
    clear_presel()
end)
hl.on("window.open", clear_presel)

-- Move the focused window into the preselection
bind("SUPER + y", function()
    local w = hl.get_active_window()
    if not presel or not w or w.address == presel then return end
    local target
    for _, c in ipairs(hl.get_windows()) do
        if c.address == presel then target = c break end
    end
    if not target or not target.workspace then return clear_presel() end
    hl.dispatch(hl.dsp.window.move({ workspace = "special:presel", follow = false }))
    hl.dispatch(hl.dsp.focus({ window = target }))
    hl.dispatch(hl.dsp.window.move({ window = w, workspace = target.workspace, follow = false }))
    hl.dispatch(hl.dsp.focus({ window = w }))
    clear_presel()
end)

-- Next/previous window
local function cycle(prev)
    local ws = hl.get_active_workspace()
    if ws and ws.tiled_layout == "monocle" then
        hl.dispatch(hl.dsp.layout(prev and "cycleprev" or "cyclenext"))
    else
        hl.dispatch(hl.dsp.window.cycle_next({ next = not prev }))
    end
end
bind("SUPER + c",         function() cycle(false) end, { repeating = true })
bind("SUPER + SHIFT + c", function() cycle(true) end, { repeating = true })

-- Prev/next workspace of this monitor
local ranges = { ["DP-2"] = { 1, 5 }, ["DP-1"] = { 6, 7 }, ["HDMI-A-1"] = { 8, 9 } }
local function step(delta)
    local ws = hl.get_active_workspace()
    local r = ws and ws.monitor and ranges[ws.monitor.name]
    if not ws or not r then return hl.dispatch(hl.dsp.focus({ workspace = delta > 0 and "m+1" or "m-1" })) end
    local id = ws.id + delta
    if id > r[2] then id = r[1] elseif id < r[1] then id = r[2] end
    hl.dispatch(hl.dsp.focus({ workspace = id }))
end
bind("CTRL + ALT + h", function() step(-1) end, { repeating = true })
bind("CTRL + ALT + l", function() step(1) end, { repeating = true })
bind("ALT + Tab",      hl.dsp.focus({ last = true }))
bind("SUPER + Tab",    notch("overview", hl.dsp.focus({ workspace = "previous" })))

for i = 1, 9 do
    bind("SUPER + " .. i,         hl.dsp.focus({ workspace = i }))
    bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i, follow = false }))
end

-- Move/Resize

-- Expand or contract
local grow = { h = { -20, 0 }, l = { 20, 0 }, j = { 0, 20 }, k = { 0, -20 } }
for key, d in pairs(grow) do
    local dx, dy = math.abs(d[1]), math.abs(d[2])
    bind("SUPER + CTRL + " .. key,       hl.dsp.window.resize({ x = dx,  y = dy,  relative = true }), { repeating = true })
    bind("SUPER + CTRL + ALT + " .. key, hl.dsp.window.resize({ x = -dx, y = -dy, relative = true }), { repeating = true })
    bind("ALT + SHIFT + " .. key,        hl.dsp.window.move({ x = d[1] * 4, y = d[2] * 4, relative = true }), { repeating = true })
end

-- Balance function
local function balance(wsid)
    local function rects()
        local out = {}
        for _, w in ipairs(hl.get_workspace_windows(tostring(wsid))) do
            if not w.floating and not w.hidden then
                out[#out + 1] = { w = w, x = w.at.x, y = w.at.y, r = w.at.x + w.size.x, b = w.at.y + w.size.y }
            end
        end
        return out
    end
    local function fresh(group)
        local by, out = {}, {}
        for _, g in ipairs(rects()) do by[g.w.address] = g end
        for _, g in ipairs(group) do out[#out + 1] = by[g.w.address] end
        return out
    end
    local function cut(group, lo, hi)
        table.sort(group, function(a, b) return a[lo] < b[lo] end)
        for i = 1, #group - 1 do
            local edge = 0
            for j = 1, i do edge = math.max(edge, group[j][hi]) end
            if edge <= group[i + 1][lo] then
                local a, b = {}, {}
                for j, g in ipairs(group) do if j <= i then a[#a + 1] = g else b[#b + 1] = g end end
                return a, b, edge
            end
        end
    end
    local function solve(group)
        if #group < 2 then return end
        local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
        for _, g in ipairs(group) do
            x0, y0 = math.min(x0, g.x), math.min(y0, g.y)
            x1, y1 = math.max(x1, g.r), math.max(y1, g.b)
        end
        local axes = (x1 - x0 >= y1 - y0) and { { "x", "r" }, { "y", "b" } } or { { "y", "b" }, { "x", "r" } }
        for _, ax in ipairs(axes) do
            local a, b, edge = cut(group, ax[1], ax[2])
            if a then
                local start, size = ax[1] == "x" and x0 or y0, ax[1] == "x" and (x1 - x0) or (y1 - y0)
                local delta = math.floor(start + size * #a / #group - edge + 0.5)
                if math.abs(delta) > 1 then
                    for _, g in ipairs(a) do
                        if g[ax[2]] == edge then
                            hl.dispatch(hl.dsp.focus({ window = g.w }))
                            hl.dispatch(hl.dsp.window.resize(ax[1] == "x" and { x = delta, y = 0, relative = true }
                                or { x = 0, y = delta, relative = true }))
                            break
                        end
                    end
                end
                solve(fresh(a))
                solve(fresh(b))
                return
            end
        end
    end
    solve(rects())
end

bind("SUPER + b", function()
    local active = hl.get_active_window()
    if not active or not active.workspace then return end
    local cursor = hl.get_cursor_pos()
    balance(active.workspace.id)
    hl.dispatch(hl.dsp.focus({ window = active }))
    if cursor then hl.dispatch(hl.dsp.cursor.move({ x = cursor.x, y = cursor.y })) end
end)

-- Mouse: Alt + LMB move, Alt + RMB resize
bind("ALT + mouse:272", hl.dsp.window.drag(),   { mouse = true })
bind("ALT + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Discord
bind("code:191",   hl.dsp.global("discord:discord-toggle-mute"))
bind("CTRL + F12", hl.dsp.global("discord:discord-toggle-deafen"))
