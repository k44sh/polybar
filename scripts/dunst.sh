#!/usr/bin/env sh
#
# Dunst pause state for polybar, red outlined bell while snoozed.
# --toggle pauses or resumes notifications.

set -eu

command -v dunstctl >/dev/null || exit 0

# Dunst is polled every second over dbus, never wait on a stuck daemon.
IPC_TIMEOUT=2
SNOOZE_COLOR=EC0101

if [ "${1:-}" = "--toggle" ]; then
    exec timeout "$IPC_TIMEOUT" dunstctl set-paused toggle
fi

paused=$(timeout "$IPC_TIMEOUT" dunstctl is-paused 2>/dev/null) || exit 0

if [ "$paused" = "true" ]; then
    printf '%%{T2}%%{F#%s}󰵛%%{F-}%%{T-}\n' "$SNOOZE_COLOR"
else
    printf '%%{T2}󰵚%%{T-}\n'
fi
