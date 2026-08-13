#!/usr/bin/env sh
#
# VPN status for polybar, internal/network cannot handle it: a tunnel operstate stays "unknown".
# Driven by the NetworkManager profile, which also yields the device it currently runs on.
# Rates come from kernel counter deltas between two runs.
# Usage: vpn.sh [--toggle] [profile]

set -eu

# shellcheck source=machine.env
. "${XDG_CONFIG_HOME:-$HOME/.config}/polybar/machine.env"

TOGGLE=0
if [ "${1:-}" = "--toggle" ]; then
    TOGGLE=1
    shift
fi
PROFILE=${1:-$POLYBAR_VPN0}

STATE="${XDG_RUNTIME_DIR:-/tmp}/polybar-vpn-$PROFILE"
NM_TIMEOUT=10
MAX_GAP=10
UP_COLOR=98C379
DOWN_COLOR=D19A66
ICON_UP="󰌾"
ICON_DOWN="󱙱"

# The device is asked to NetworkManager rather than derived from the profile
# name: a tunnel device only exists while up, and OpenVPN names it at runtime.
device() {
    LC_ALL=C timeout "$NM_TIMEOUT" nmcli -g GENERAL.DEVICES connection show --active "$PROFILE" 2>/dev/null || true
}

if [ "$TOGGLE" = 1 ]; then
    if [ -n "$(device)" ]; then
        exec nmcli -w "$NM_TIMEOUT" connection down "$PROFILE"
    fi
    exec nmcli -w "$NM_TIMEOUT" connection up "$PROFILE"
fi

address_of() {
    [ -n "$1" ] || return 0
    # shellcheck disable=SC2046  # splitting the fields is the point
    set -- $(ip -4 -o addr show "$1" 2>/dev/null)
    # An if, not a && chain: the chain returns 1 with no address, and set -e then
    # kills the caller before it prints the disconnected state.
    if [ $# -ge 4 ]; then
        printf '%s' "${4%%/*}"
    fi
}

iface="" prev_rx="" prev_tx="" prev_time=""
[ -f "$STATE" ] && read -r iface prev_rx prev_tx prev_time <"$STATE" || true

# The cached device answers with a plain kernel read. NetworkManager is only
# asked when it stops answering, which also catches a tunnel moving device.
ip_addr=$(address_of "$iface")
if [ -z "$ip_addr" ]; then
    iface=$(device)
    ip_addr=$(address_of "$iface")
    prev_rx="" prev_tx="" prev_time=""
fi

if [ -z "$ip_addr" ]; then
    printf '%%{F#%s}%%{T2}%s%%{T-}%%{F-} %s' "$DOWN_COLOR" "$ICON_DOWN" "$PROFILE"
    exit 0
fi

read -r rx <"/sys/class/net/$iface/statistics/rx_bytes"
read -r tx <"/sys/class/net/$iface/statistics/tx_bytes"
now=$(date +%s)

# A gap means polybar or the tunnel restarted, the counters cannot be compared.
[ -n "$prev_time" ] && [ $((now - prev_time)) -gt "$MAX_GAP" ] && prev_rx="" prev_tx="" prev_time=""
echo "$iface $rx $tx $now" >"$STATE"

elapsed=$((now - ${prev_time:-$((now - 1))}))
[ "$elapsed" -gt 0 ] || elapsed=1
rx_rate=$(((rx - ${prev_rx:-$rx}) / elapsed))
[ "$rx_rate" -ge 0 ] || rx_rate=0
tx_rate=$(((tx - ${prev_tx:-$tx}) / elapsed))
[ "$tx_rate" -ge 0 ] || tx_rate=0

# Bytes, like the internal network modules, which polybar cannot switch to bits.
rates=$(awk -v r="$rx_rate" -v t="$tx_rate" 'function h(b) {
    if (b >= 1048576) return sprintf("%.1f MB/s", b/1048576)
    if (b >= 1024)    return sprintf("%.0f KB/s", b/1024)
    return sprintf("%d B/s", b)
} BEGIN {printf "↓%s ↑%s", h(r), h(t)}')

printf '%%{F#%s}%%{T2}%s%%{T-}%%{F-} %s %s %s' "$UP_COLOR" "$ICON_UP" "$PROFILE" "$ip_addr" "$rates"
