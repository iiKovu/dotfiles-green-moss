#!/bin/sh

. ~/.config/themes/current/preset.sh

MONITORS=$(xrandr -q)
set --

echo "$MONITORS" | grep -q 'DisplayPort-1 connected' && set -- "$@" --output DisplayPort-1 --maximize "$WALLPAPER_CENTER"
echo "$MONITORS" | grep -q 'DisplayPort-0 connected' && set -- "$@" --output DisplayPort-0 --center "$WALLPAPER_LEFT"
echo "$MONITORS" | grep -q 'HDMI-A-0 connected' && set -- "$@" --output HDMI-A-0 --zoom "$WALLPAPER_UP"

xwallpaper "$@"
