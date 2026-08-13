#!/usr/bin/env sh
#
# Rofi power menu, opened from the bar. The lock command is the only part
# tied to a package, swap it if you use another locker.

set -eu

MENU="$HOME/.config/polybar/scripts/rofi.sh"
LOCK=i3lock-fancy
LOCK_DELAY=1

choice=$(printf '%s\n' \
    " Lock" \
    " Suspend" \
    "󰗼 Logout" \
    "↻ Reboot" \
    "󰐥 Shutdown" | "$MENU" "$(uname -n)") || exit 0

case "$choice" in
    *Lock) exec "$LOCK" ;;
    *Suspend)
        # Lock first so the screen is already covered when it resumes.
        "$LOCK" &
        sleep "$LOCK_DELAY"
        exec systemctl suspend
        ;;
    *Logout) exec i3-msg exit ;;
    *Reboot) exec systemctl reboot ;;
    *Shutdown) exec systemctl poweroff ;;
esac
