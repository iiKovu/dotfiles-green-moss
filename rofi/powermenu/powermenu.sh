#!/bin/bash

# Current Theme
dir="$HOME/.config/rofi/powermenu/"
theme_file='powermenu-config'

# Options
shutdown=''
reboot=''
suspend=''
logout=''
theme=''

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "Be good..." \
		-mesg "<i>Stay humble</i>" \
		-theme "${dir}/${theme_file}.rasi"
}

# Pass variables to rofi dmenu
run_rofi() {
	printf '%s\n' "$shutdown" "$reboot" "$suspend" "$logout" "$theme" | rofi_cmd
}

# Theme picker: same look, preset names instead of icons
themectl="$HOME/Documents/scripts/theme.sh"
pick_theme() {
	local presets active row
	mapfile -t presets < <("$themectl" | cut -c3-)
	active=$("$themectl" | awk '$1 == "*" {print $2}')
	for row in "${!presets[@]}"; do
		[[ ${presets[$row]} == "$active" ]] && break
	done
	printf '%s\n' "${presets[@]}" | rofi -dmenu \
		-p "Pick a look..." \
		-mesg "<i>${active}</i>" \
		-selected-row "$row" \
		-theme "${dir}/${theme_file}.rasi" \
		-theme-str "listview { columns: ${#presets[@]}; } element-text { font: \"Noto Sans JP Italic 26\"; }"
}

# Actions
chosen="$(run_rofi)"
case "$chosen" in
"$shutdown")
	systemctl poweroff
	;;
"$reboot")
	systemctl reboot
	;;
"$suspend")
	systemctl suspend
	;;
"$logout")
	bspc quit
	;;
"$theme")
	chosen_theme="$(pick_theme)"
	[[ -n $chosen_theme ]] && "$themectl" "$chosen_theme"
	;;
esac
