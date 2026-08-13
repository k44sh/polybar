#!/usr/bin/env sh
#
# Default microphone state for polybar, red icon when muted.
# --toggle mutes or unmutes the default source.

set -eu

# The pactl output is parsed, keep it in English.
export LC_ALL=C

# The audio server is polled every second, never wait on a wedged one.
IPC_TIMEOUT=2
MUTED_COLOR=EC0101
LIVE_COLOR=98C379

if [ "${1:-}" = "--toggle" ]; then
    exec timeout "$IPC_TIMEOUT" pactl set-source-mute @DEFAULT_SOURCE@ toggle
fi

muted=$(timeout "$IPC_TIMEOUT" pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null) || exit 0

if [ "$muted" = "Mute: yes" ]; then
    printf '%%{T2}%%{F#%s}󰍭%%{F-}%%{T-}' "$MUTED_COLOR"
else
    printf '%%{T2}%%{F#%s}󰍬%%{F-}%%{T-}' "$LIVE_COLOR"
fi
