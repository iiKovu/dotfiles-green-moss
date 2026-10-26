#!/bin/sh

. ~/.config/themes/current/preset.sh

# Wait for hyprpaper's IPC (autostart launches both at once)
i=0
until hyprctl hyprpaper listactive >/dev/null 2>&1 || [ $i -ge 50 ]; do
    sleep 0.1
    i=$((i + 1))
done

# Same monitors as x11/wallpaper.sh, under their DRM names
hyprctl hyprpaper wallpaper "DP-2, $WALLPAPER_CENTER, contain"
hyprctl hyprpaper wallpaper "DP-1, $WALLPAPER_LEFT, contain"
hyprctl hyprpaper wallpaper "HDMI-A-1, $WALLPAPER_UP, cover"
