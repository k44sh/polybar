#!/usr/bin/env sh
#
# Rofi dmenu wrapper anchored under the bar, width and height fit the piped list.
# Usage: printf '...' | rofi.sh "Prompt"
#        rofi.sh --password "Prompt"

set -eu

THEME="$HOME/.config/polybar/rofi/menu.rasi"
CHAR_WIDTH_PX=10
PADDING_PX=120
MIN_WIDTH_PX=340
MAX_WIDTH_PX=1000
PASSWORD_WIDTH_PX=500
MAX_LINES=10

if [ "${1:-}" = "--password" ]; then
    exec rofi -dmenu -password -p "$2" -theme "$THEME" \
        -theme-str "window {width: ${PASSWORD_WIDTH_PX}px;} listview {lines: 0;}" \
        </dev/null
fi

list=$(cat)
[ -n "$list" ] || exit 1

longest=$(printf '%s\n' "$list" | wc -L)
width=$((longest * CHAR_WIDTH_PX + PADDING_PX))
if [ "$width" -lt "$MIN_WIDTH_PX" ]; then width=$MIN_WIDTH_PX; fi
if [ "$width" -gt "$MAX_WIDTH_PX" ]; then width=$MAX_WIDTH_PX; fi

lines=$(printf '%s\n' "$list" | wc -l)
if [ "$lines" -gt "$MAX_LINES" ]; then lines=$MAX_LINES; fi

printf '%s\n' "$list" | rofi -dmenu -i -p "$1" -theme "$THEME" \
    -theme-str "window {width: ${width}px;} listview {lines: ${lines};}"
