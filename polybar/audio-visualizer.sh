#!/usr/bin/env bash

bars="${1:-20}"
fps="${2:-120}"
sensitivity="${3:-100}"
config="$(mktemp -t polybar-cava.XXXXXX)"

cleanup() {
	rm -f "$config"
}
trap cleanup EXIT
trap 'cleanup; exit 0' INT TERM

cat >"$config" <<EOF
[general]
bars = $bars
framerate = $fps
autosens = 1
sensitivity = $sensitivity

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

cava -p "$config" 2>/dev/null |
	while IFS=';' read -ra levels; do
		out=""
		for level in "${levels[@]}"; do
			case "$level" in
				0) out+="▁" ;;
				1) out+="▂" ;;
				2) out+="▃" ;;
				3) out+="▄" ;;
				4) out+="▅" ;;
				5) out+="▆" ;;
				6) out+="▇" ;;
				7) out+="█" ;;
			esac
		done
		printf '%s\n' "$out"
	done
