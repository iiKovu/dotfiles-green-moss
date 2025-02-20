#!/bin/bash

# Terminate already running bar instances
killall -q polybar
sleep 0.5

# Launch the bar
polybar top &

if [[ $(xrandr -q | grep 'DisplayPort-1 connected') ]]; then
	polybar second &
fi

if [[ $(xrandr -q | grep 'HDMI-A-0 connected') ]]; then
	polybar third &
fi
