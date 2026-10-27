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

# GTK reads settings.ini on X11 but gsettings on Wayland: mirror settings.ini so both match
# (gtk-4.0/settings.ini is a symlink to it)
ini="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
gtk_get() { sed -n "s/^$1=//p" "$ini"; }
gtk_set() { [[ -n $2 ]] && gsettings set org.gnome.desktop.interface "$1" "$2"; }
if [[ -f $ini ]]; then
    gtk_set gtk-theme "$(gtk_get gtk-theme-name)"
    gtk_set icon-theme "$(gtk_get gtk-icon-theme-name)"
    gtk_set font-name "$(gtk_get gtk-font-name)"
    gtk_set cursor-theme "$(gtk_get gtk-cursor-theme-name)"
    gtk_set cursor-size "$(gtk_get gtk-cursor-theme-size)"
    gtk_set font-hinting "$(gtk_get gtk-xft-hintstyle | sed 's/^hint//')"
    rgba=$(gtk_get gtk-xft-rgba)
    case "$(gtk_get gtk-xft-antialias),$rgba" in
    0,*) gtk_set font-antialiasing none ;;
    *,none | *,) gtk_set font-antialiasing grayscale ;;
    *) gtk_set font-antialiasing rgba && gtk_set font-rgba-order "$rgba" ;;
    esac
fi

if pgrep -x bspwm >/dev/null; then
    bspc config focused_border_color "$BORDER_FOCUSED"
    bspc config normal_border_color "$BORDER_NORMAL"
    "$HOME/Documents/scripts/x11/wallpaper.sh"
    "$themes/../polybar/launch.sh" >/dev/null 2>&1 &
elif pgrep -x Hyprland >/dev/null; then
    hyprctl reload >/dev/null # hypr/preset.lua re-reads the preset
    "$HOME/Documents/scripts/wayland/wallpaper.sh" >/dev/null
    "$HOME/Documents/scripts/wayland/bar.sh"  # notch or waybar, per preset
    pkill -USR2 -x waybar # reload style (re-imports the preset colors)
fi
pkill -USR1 -x kitty
pgrep -x dunst >/dev/null && dunstctl reload
wait
notify-send "Theme" "$1"
