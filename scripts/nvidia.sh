#!/usr/bin/env sh
#
# Compact GPU monitoring for polybar.
# A flock-protected cache guarantees a single nvidia-smi query per refresh window.

set -eu

command -v nvidia-smi >/dev/null || exit 0

QUERY_TIMEOUT=3
WARN_COLOR=EC0101
GPU_WARN=95
TEMP_WARN=90
VRAM_WARN=80

reading=$(timeout "$QUERY_TIMEOUT" nvidia-smi \
    --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.reserved,memory.total \
    --format=csv,noheader,nounits 2>/dev/null) || exit 0
# Split in place: a here-document or a pipe would each cost a process.
IFS=', '
set -- $reading
IFS=' '
[ $# -ge 5 ] || exit 0
gpu=$1 temp=$2 used=$3 reserved=$4 total=$5

seg() {
    if [ "$3" -ge "$4" ]; then
        printf '%%{F#%s}%%{T2}%s%%{T-}%s %s%%{F-}' "$WARN_COLOR" "$1" "$2" "$5"
    else
        printf '%%{T2}%s%%{T-}%s %s' "$1" "$2" "$5"
    fi
}

vram=$(((used + reserved) * 100 / total))
seg "󰍹" " GPU" "$gpu" "$GPU_WARN" "$gpu%"
printf '  '
seg "󰔐" "" "$temp" "$TEMP_WARN" "$temp°C"
printf '  '
seg "󰍛" "" "$vram" "$VRAM_WARN" "$vram%"
printf '\n'
