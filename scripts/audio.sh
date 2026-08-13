#!/usr/bin/env sh
#
# Rofi picker for the default audio device, moves active streams to it.
# Usage: audio.sh [sink|source]

set -eu

# The pactl output is parsed, keep it in English.
export LC_ALL=C

IPC_TIMEOUT=5

kind=${1:-sink}
case "$kind" in
    sink) prompt="Sortie audio" ;;
    source) prompt="Micro" ;;
    *) exit 2 ;;
esac

current=$(timeout "$IPC_TIMEOUT" pactl "get-default-$kind")

# Monitors mirror a sink and easyeffects devices are plumbing, neither is a real choice.
devices=$(timeout "$IPC_TIMEOUT" pactl list "${kind}s" | awk -v current="$current" '
    /^\tName:/ {name=$2}
    /^\tDescription:/ {
        sub(/.*Description: /, "")
        if (name !~ /\.monitor$/ && name !~ /^easyeffects_/)
            printf "%s\t%s%s\n", name, (name==current ? "● " : "  "), $0
    }')

choice=$(printf '%s\n' "$devices" | cut -f2 | "$HOME/.config/polybar/scripts/rofi.sh" "$prompt") || exit 0
[ -n "$choice" ] || exit 0
device=$(printf '%s\n' "$devices" | awk -F'\t' -v choice="$choice" '$2==choice {print $1; exit}')
[ -n "$device" ] || exit 0

timeout "$IPC_TIMEOUT" pactl "set-default-$kind" "$device"

if [ "$kind" = "sink" ]; then
    timeout "$IPC_TIMEOUT" pactl list short sink-inputs | cut -f1 | while read -r stream; do
        timeout "$IPC_TIMEOUT" pactl move-sink-input "$stream" "$device"
    done
else
    timeout "$IPC_TIMEOUT" pactl list short source-outputs | cut -f1 | while read -r stream; do
        timeout "$IPC_TIMEOUT" pactl move-source-output "$stream" "$device"
    done
fi
