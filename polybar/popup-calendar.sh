#!/bin/sh
BAR_HEIGHT=37
BORDER_SIZE=5
CAL_WIDTH=282
CAL_HEIGHT=193
PADDING=8
CAL_TITLE="yad-calendar"

if [ "$1" = "--popup" ]; then
	command -v yad >/dev/null 2>&1 || exit 1
	command -v xdotool >/dev/null 2>&1 || exit 1
	command -v xrandr >/dev/null 2>&1 || exit 1

	[ "$(xdotool getwindowfocus getwindowname 2>/dev/null)" = "$CAL_TITLE" ] && exit 0

	eval "$(xdotool getmouselocation --shell 2>/dev/null)"
	mouse_x=${X:-0}
	mouse_y=${Y:-0}

	xrandr_output=$(xrandr --query)

	set -- $(echo "$xrandr_output" | awk -v mx="$mouse_x" -v my="$mouse_y" '
	/ connected/ {
	  for (i=1;i<=NF;i++) if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/) {
	    split($i,a,/[x+]/); x=a[3]; y=a[4]; w=a[1]; h=a[2];
	    if (mx>=x && mx<x+w && my>=y && my<y+h) {print x,y,w,h; exit}
	  }
	}')
	[ -z "$1" ] && set -- $(echo "$xrandr_output" | awk '
	/ connected primary/ || / connected/ {
	  for (i=1;i<=NF;i++) if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/) {
	    split($i,a,/[x+]/); print a[3],a[4],a[1],a[2]; exit}
	}')

	mon_x=$1
	mon_y=$2
	mon_width=$3
	[ -n "$mon_x" ] || mon_x=0
	[ -n "$mon_y" ] || mon_y=0
	[ -n "$mon_width" ] || mon_width=1920

	pos_x=$((mon_x + mon_width - CAL_WIDTH - PADDING))
	pos_y=$((mon_y + BAR_HEIGHT + BORDER_SIZE))

	exec yad --calendar --undecorated --fixed --close-on-unfocus --no-buttons \
		--width=$CAL_WIDTH --height=$CAL_HEIGHT \
		--posx=$pos_x --posy=$pos_y --title="$CAL_TITLE" --borders=0 >/dev/null
else
	date +"%D"
fi
