#!/bin/sh

# Click a window and keep it on top (Wayland version of `bspc node $(xdotool selectwindow) -l above`).
# Hyprland has no "above" layer: floating windows sit over tiled ones, and only pinned ones over
# fullscreen, so float, pin (which also shows it on every workspace) and raise it.
workspaces=$(hyprctl -j monitors | jq '[.[].activeWorkspace.id]')
address=$(hyprctl -j clients |
    jq -r --argjson ws "$workspaces" \
        '.[] | select(.workspace.id as $id | $ws | index($id)) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1]) \(.address)"' |
    slurp -r -f '%l') || exit 1

hyprctl dispatch "hl.dsp.window.float({ action = 'enable', window = 'address:$address' })" >/dev/null
hyprctl dispatch "hl.dsp.window.pin({ action = 'enable', window = 'address:$address' })" >/dev/null
hyprctl dispatch "hl.dsp.window.alter_zorder({ mode = 'top', window = 'address:$address' })" >/dev/null
