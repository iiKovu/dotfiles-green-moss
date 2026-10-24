#!/bin/sh

command -v playerctl >/dev/null 2>&1 || exit 0

playerctl --player=spotify,%any metadata --format '{{artist}} · {{title}}' 2>/dev/null |
	awk 'length > 48 { print substr($0, 1, 45) "..."; next } { print }'
