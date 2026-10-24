#!/bin/sh
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}"
[ -w "$STATE_DIR" ] || STATE_DIR="/tmp"
STATE_FILE="$STATE_DIR/polybar-tray-state"

if [ ! -f "$STATE_FILE" ] || [ "$(cat "$STATE_FILE")" = "hidden" ]; then
	printf '%s\n' "visible" > "$STATE_FILE"
	polybar-msg action "#tray.module_show" >/dev/null
	polybar-msg action "#tray-toggle.hook.1" >/dev/null
else
	printf '%s\n' "hidden" > "$STATE_FILE"
	polybar-msg action "#tray.module_hide" >/dev/null
	polybar-msg action "#tray-toggle.hook.0" >/dev/null
fi
