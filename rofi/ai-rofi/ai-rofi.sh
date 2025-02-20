#!/bin/bash

# Configuration
MODEL=${MODEL:-"llama3.2:1b"}
TIMEOUT=${TIMEOUT:-30}
HISTORY_FILE="$HOME/.config/rofi/ai-rofi/history.txt"

# Main loop
while true; do
	# User Input
	user_input=$(rofi -dmenu -theme-str 'window { width: 15%; height: 5%; } entry { placeholder: "Ask AI..."; }')

	# Exit conditions
	if [[ -z "$user_input" || "$user_input" == "exit" ]]; then
		break
	fi

	# Show history
	if [[ "$user_input" == "hist" ]]; then
		[ -s "$HISTORY_FILE" ] && cat "$HISTORY_FILE" | rofi -dmenu -theme-str 'window { width: 20%; height: 20%; } listview { lines: 5; }' || rofi -e "History is empty..."
		continue
	fi

	# Clear history
	if [[ "$user_input" == "clear" ]]; then
		>"$HISTORY_FILE"
		rofi -e "History cleared..."
		continue
	fi

	# Show loading indicator (small)
	rofi -e "Thinking..." &
	rofi_pid=$!

	# Get AI response with timeout
	ai_response=$(timeout "$TIMEOUT" ollama run "$MODEL" <<<"$user_input")
	if [ $? -eq 124 ]; then
		ai_response="The AI response timed out. Please try again."
	fi

	# Kill loading indicator
	kill $rofi_pid

	# Display AI response
	rofi -e "$ai_response" -theme-str 'window { width: 15%; } listview { lines: 5; }'

	# Save to history
	{
		echo "Me: $user_input"
		echo "AI: $ai_response"
	} >>"$HISTORY_FILE"

	# Keep only the last 200 entries
	tail -n 200 "$HISTORY_FILE" >"$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"

done
