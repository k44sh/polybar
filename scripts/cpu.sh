#!/usr/bin/env sh
#
# Compact CPU monitoring for polybar: load, package temperature and used memory.
# Load is averaged over the interval from /proc/stat deltas, an instant sample means nothing.

set -eu

# Machine identifiers, shared with the ini files.
# shellcheck source=machine.env
. "${XDG_CONFIG_HOME:-$HOME/.config}/polybar/machine.env"

STATE="${XDG_RUNTIME_DIR:-/tmp}/polybar-cpu"
THERMAL_TYPE=$POLYBAR_THERMAL
WARN_COLOR=EC0101
CPU_WARN=90
TEMP_WARN=90
MEM_WARN=80

read -r _ user nice system idle iowait irq softirq steal _ </proc/stat
total=$((user + nice + system + idle + iowait + irq + softirq + steal))
busy=$((total - idle - iowait))

zone="" prev_total="" prev_busy=""
[ -f "$STATE" ] && read -r zone prev_total prev_busy <"$STATE" || true

# Scanning every zone costs one read each, so the match is cached. Zone
# numbering is not stable across boots, hence the check before reuse.
if [ ! -r "$zone/temp" ]; then
    zone=""
    for candidate in /sys/class/thermal/thermal_zone*; do
        if [ "$(cat "$candidate/type" 2>/dev/null)" = "$THERMAL_TYPE" ]; then
            zone=$candidate
            break
        fi
    done
fi
echo "$zone $total $busy" >"$STATE"

elapsed=$((total - ${prev_total:-0}))
cpu=0
if [ "$elapsed" -gt 0 ]; then
    cpu=$(((busy - ${prev_busy:-0}) * 100 / elapsed))
fi

temp=""
if [ -n "$zone" ]; then
    # The kernel reports millidegrees.
    read -r millidegrees <"$zone/temp"
    temp=$((millidegrees / 1000))
fi

# /proc/meminfo avoids the free and awk pair, used is total minus available.
mem_total=1 mem_available=0
while read -r key value _; do
    case $key in
        MemTotal:) mem_total=$value ;;
        MemAvailable:)
            mem_available=$value
            break
            ;;
    esac
done </proc/meminfo
mem=$(((mem_total - mem_available) * 100 / mem_total))

seg() {
    if [ "$3" -ge "$4" ]; then
        printf '%%{F#%s}%%{T2}%s%%{T-}%s %s%%{F-}' "$WARN_COLOR" "$1" "$2" "$5"
    else
        printf '%%{T2}%s%%{T-}%s %s' "$1" "$2" "$5"
    fi
}

seg "󰊚" " CPU" "$cpu" "$CPU_WARN" "$cpu%"
printf '  '
if [ -n "$temp" ]; then
    seg "󰔐" "" "$temp" "$TEMP_WARN" "$temp°C"
    printf '  '
fi
seg "󰍛" "" "$mem" "$MEM_WARN" "$mem%"
printf '\n'
