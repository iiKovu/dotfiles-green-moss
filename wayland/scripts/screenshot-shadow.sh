#!/bin/sh

# Click a window, save it with a drop shadow (Wayland version of the maim bind)
file="$HOME/Documents/Pictures/screenshots/Shadow/$(date +%F_%H-%M-%S)_shadow.png"

workspaces=$(hyprctl -j monitors | jq '[.[].activeWorkspace.id]')
geometry=$(hyprctl -j clients |
    jq -r --argjson ws "$workspaces" \
        '.[] | select(.workspace.id as $id | $ws | index($id)) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' |
    slurp -r) || exit 1

grim -g "$geometry" - |
    magick - \( +clone -background black -shadow 80x3+5+5 \) +swap -background none -layers merge +repage "$file" &&
    notify-send 'Screenshot Taken' 'Shadow Window' -i "$file"
