#!/bin/sh

BAR_HEIGHT=34
BORDER_SIZE=20
YAD_WIDTH=222
YAD_HEIGHT=193
X_OFFSET=796

if [ "$1" = "--popup" ]; then
	if [ "$(xdotool getwindowfocus getwindowname 2>/dev/null)" = "yad-calendar" ]; then
		exit 0
	fi

	# Set fixed position relative to Polybar (below the bar)
	pos_x="$X_OFFSET"
	pos_y=$((BAR_HEIGHT + BORDER_SIZE))

	# Launch YAD calendar
	yad --calendar --undecorated --fixed --close-on-unfocus --no-buttons \
		--width="$YAD_WIDTH" --height="$YAD_HEIGHT" --posx="$pos_x" --posy="$pos_y" \
		--title="yad-calendar" --borders=0 >/dev/null &
else
	# Print the current date
	date +"%D"
fi
