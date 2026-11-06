#!/bin/sh
# Starts the Hyprland bar: the Quickshell notch, which also handles notifications.

pkill -x waybar
pgrep -x quickshell >/dev/null || setsid -f quickshell >/dev/null 2>&1
# Once the notch has loaded, it takes the notification name as soon as dunst lets go
i=0
until qs ipc call notch current >/dev/null 2>&1 || [ $i -ge 50 ]; do
    sleep 0.1
    i=$((i + 1))
done
pkill -x dunst
