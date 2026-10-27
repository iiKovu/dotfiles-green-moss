#!/bin/sh
# Starts the Hyprland bar for the active preset: the Quickshell notch when the
# preset has a quickshell.json (it also handles notifications), waybar + dunst otherwise.

if [ -f ~/.config/themes/current/quickshell.json ]; then
    pkill -x waybar
    pgrep -x quickshell >/dev/null || setsid -f quickshell >/dev/null 2>&1
    # Once the notch has loaded, it takes the notification name as soon as dunst lets go
    i=0
    until qs ipc call notch current >/dev/null 2>&1 || [ $i -ge 50 ]; do
        sleep 0.1
        i=$((i + 1))
    done
    pkill -x dunst
else
    pkill -x quickshell
    pgrep -x waybar >/dev/null || setsid -f waybar >/dev/null 2>&1
    pgrep -x dunst >/dev/null || setsid -f dunst >/dev/null 2>&1
fi
