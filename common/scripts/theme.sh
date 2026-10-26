#!/usr/bin/env bash

themes="${XDG_CONFIG_HOME:-$HOME/.config}/themes"
active=$(readlink "$themes/current")

if [[ $# -eq 0 ]]; then
    for d in "$themes"/*/; do
        name=$(basename "$d")
        [[ $name == current ]] && continue
        [[ $name == "$active" ]] && echo "* $name" || echo "  $name"
    done
    exit 0
fi

[[ -d "$themes/$1" && $1 != current ]] || {
    echo "theme: no preset '$1'" >&2
    exit 1
}
ln -sfn "$1" "$themes/current"
. "$themes/current/preset.sh"

gtk="${XDG_DATA_HOME:-$HOME/.local/share}/themes"
[[ -d "$gtk/$GTK_NAME" ]] && target="$gtk/$GTK_NAME" || target="/usr/share/themes/$GTK_NAME"
[[ -d $target ]] && ln -sfn "$target" "$gtk/Orchis-Preset" ||
    notify-send -u critical "Theme" "No GTK theme $GTK_NAME (build-gtk-theme.sh $1)"

if pgrep -x bspwm >/dev/null; then
    bspc config focused_border_color "$BORDER_FOCUSED"
    bspc config normal_border_color "$BORDER_NORMAL"
    "$HOME/Documents/scripts/x11/wallpaper.sh"
    "$themes/../polybar/launch.sh" >/dev/null 2>&1 &
fi
pkill -USR1 -x kitty
pgrep -x dunst >/dev/null && dunstctl reload
wait
notify-send "Theme" "$1"
