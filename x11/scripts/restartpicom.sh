#!/usr/bin/env bash

# Run with a suffix to try a variant. No suffix runs picom.conf.
config="${XDG_CONFIG_HOME:-$HOME/.config}/picom/picom.conf${1:+.$1}"
[ -f "$config" ] || { notify-send -u critical "Picom" "No $config"; exit 1; }

was_running=false
pgrep -x picom >/dev/null && was_running=true
pkill -x picom >/dev/null 2>&1 || true

while pgrep -x picom >/dev/null; do
	sleep 0.8
done

picom --config "$config" &
$was_running && notify-send "Picom restarted"
