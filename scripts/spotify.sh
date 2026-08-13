#!/usr/bin/env sh
#
# Polybar tail module. Follows spotify over MPRIS, and notifies with the album cover on track change.

set -eu

command -v playerctl >/dev/null || exit 0

COVERS="${XDG_RUNTIME_DIR:-/tmp}/spotify-covers"
COVER_TIMEOUT=3
COVER_MAX_AGE_MIN=1440
# Bounds the startup reads. The follower below is meant to never return.
IPC_TIMEOUT=2
NOTIFICATION_ID=27072
ACCENT_COLOR=98C379
META_MAX_LEN=45
META_TRUNC_LEN=42

mkdir -p "$COVERS"

render() {
    status=$1 artist=$2 title=$3
    if [ -z "$status" ]; then
        echo ""
        return
    fi
    if [ "$status" = "Stopped" ] || [ -z "$title" ]; then
        printf '%%{T2}%%{F#%s}󰓇%%{F-}%%{T-} Spotify\n' "$ACCENT_COLOR"
        return
    fi
    meta="$artist - $title"
    if [ -z "$artist" ]; then
        meta="$title"
    fi
    if [ "${#meta}" -gt "$META_MAX_LEN" ]; then
        meta="$(printf '%.'"$META_TRUNC_LEN"'s' "$meta")..."
    fi
    if [ "$status" = "Playing" ]; then
        state="󰐌"
    else
        state="󰏥"
    fi
    printf '%%{T2}%%{F#%s}󰓇%%{F-}%%{T-} %%{T2}%s%%{T-} %s\n' "$ACCENT_COLOR" "$state" "$meta"
}

notify() {
    track=$1 art=$2 title=$3 artist=$4
    cover="$COVERS/${track##*/}.png"
    if [ ! -s "$cover" ] && [ -n "$art" ]; then
        # Old spotify clients expose an open.spotify.com url, the image host is i.scdn.co either way.
        url=$(printf '%s' "$art" | sed 's|open\.spotify\.com|i.scdn.co|')
        curl -sf --max-time "$COVER_TIMEOUT" -o "$cover" "$url" || rm -f "$cover"
    fi
    # Dunst renders pango markup, escape what the metadata may contain.
    title=$(printf '%s' "$title" | sed 's/&/\&amp;/g; s/</\&lt;/g')
    artist=$(printf '%s' "$artist" | sed 's/&/\&amp;/g; s/</\&lt;/g')
    if [ -s "$cover" ]; then
        dunstify -a Spotify -u low -r "$NOTIFICATION_ID" -i "$cover" "$title" "$artist"
    else
        dunstify -a Spotify -u low -r "$NOTIFICATION_ID" "$title" "$artist"
    fi
    find "$COVERS" -type f -mmin "+$COVER_MAX_AGE_MIN" -delete 2>/dev/null || true
}

# The follower only emits on changes, render the current state first.
if timeout "$IPC_TIMEOUT" playerctl -l 2>/dev/null | grep -qx spotify; then
    render "$(timeout "$IPC_TIMEOUT" playerctl -p spotify status 2>/dev/null || echo Stopped)" \
        "$(timeout "$IPC_TIMEOUT" playerctl -p spotify metadata artist 2>/dev/null || true)" \
        "$(timeout "$IPC_TIMEOUT" playerctl -p spotify metadata title 2>/dev/null || true)"
else
    echo ""
fi

last_track=""
stdbuf -oL playerctl -p spotify metadata --follow \
    --format '{{mpris:trackid}}|{{status}}|{{mpris:artUrl}}|{{artist}}|{{title}}' 2>/dev/null |
    while IFS='|' read -r track status art artist title; do
        render "$status" "$artist" "$title"
        if [ "$status" = "Playing" ] && [ "$track" != "$last_track" ]; then
            last_track=$track
            notify "$track" "$art" "$title" "$artist" &
        fi
    done
