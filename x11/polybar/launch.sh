#!/usr/bin/env bash

set -u

config="${XDG_CONFIG_HOME:-$HOME/.config}/polybar/config.ini"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/polybar"
mkdir -p "$state_dir" 2>/dev/null || state_dir="${XDG_RUNTIME_DIR:-/tmp}"
log="$state_dir/polybar.log"

exec 9>"$state_dir/polybar-launch.lock"
flock -n 9 || exit 0
: >"$log"

was_running=false
pgrep -x polybar >/dev/null && was_running=true

fail() {
    notify-send -u critical "Polybar restart failed" "$1" 2>/dev/null || true
    exit 1
}

wait_for_exit() {
    local attempt
    for ((attempt = 0; attempt < 20; attempt++)); do
        pgrep -x polybar >/dev/null || return 0
        sleep 0.1
    done
    return 1
}

stop_polybar() {
    pgrep -x polybar >/dev/null || return 0
    polybar-msg cmd quit >/dev/null 2>&1 || true
    wait_for_exit && return 0
    pkill -TERM -x polybar >/dev/null 2>&1 || true
    wait_for_exit && return 0
    pkill -KILL -x polybar >/dev/null 2>&1 || true
    wait_for_exit
}

stop_polybar || fail "Existing Polybar processes did not exit."
xrandr_output=$(xrandr --query 2>>"$log") || fail "Could not query connected monitors."
mapfile -t monitors < <(awk '$2 == "connected" {print $1}' <<<"$xrandr_output")
((${#monitors[@]})) || fail "No connected monitors were detected."

connected() {
    [[ " ${monitors[*]} " == *" $1 "* ]]
}

primary=$(awk '$2 == "connected" && $3 == "primary" {print $1; exit}' <<<"$xrandr_output")
main=${primary:-${monitors[0]}}
connected DisplayPort-1 && main=DisplayPort-1

pids=()
bars=()
start_bar() {
    MONITOR="$2" polybar --reload --config="$config" "$1" >>"$log" 2>&1 9>&- &
    pids+=("$!")
    bars+=("$1 @ $2")
}

start_bar top "$main"
connected DisplayPort-0 && [[ "$main" != DisplayPort-0 ]] && start_bar second DisplayPort-0
connected HDMI-A-0 && [[ "$main" != HDMI-A-0 ]] && start_bar third HDMI-A-0

sleep 0.5
for pid in "${pids[@]}"; do
    kill -0 "$pid" 2>/dev/null || fail "A bar exited during startup. Log: $log"
done

$was_running && notify-send "Polybar restarted" "${bars[*]}" 2>/dev/null || true
