#!/usr/bin/env sh
#
# Rofi wifi picker through NetworkManager. Known networks reconnect, new secured ones ask a password.

set -eu

# The nmcli output is parsed, keep it in English.
export LC_ALL=C

CONNECT_TIMEOUT=20

# Refresh the scan cache in the background, the list below reads the cache
# rather than waiting the six seconds a blocking scan costs.
nmcli device wifi rescan 2>/dev/null || true

# The ssid comes last so escaped colons inside it can be rebuilt. nmcli lists
# one entry per band, so a network is folded to a single line: the strongest,
# unless one of its bands is the link actually in use.
networks=$(nmcli -t -f IN-USE,FREQ,SIGNAL,SECURITY,SSID device wifi list --rescan no | awk -F: '
    {
        ssid = $5
        for (i = 6; i <= NF; i++) ssid = ssid ":" $i
        gsub(/\\:/, ":", ssid)
        if (ssid == "") next

        freq = $2 + 0
        band = freq < 2500 ? "2.4 GHz" : (freq < 5925 ? "5 GHz" : "6 GHz")
        active = ($1 == "*")

        if (!(ssid in seen)) {
            order[++count] = ssid
            seen[ssid] = 1
        } else if (!active || chosen[ssid] == "active") {
            next
        }
        chosen[ssid] = active ? "active" : "best"
        mark[ssid] = active ? "●" : " "
        info[ssid] = sprintf("%-7s %-5s %3d%%", band, $4 == "" ? "open" : $4, $3)
        if (length(ssid) > width) width = length(ssid)
    }
    END {
        for (i = 1; i <= count; i++) {
            name = order[i]
            printf "%s %-*s  %s\n", mark[name], width, name, info[name]
        }
    }')
[ -n "$networks" ] || exit 0

choice=$(printf '%s\n' "$networks" | "$HOME/.config/polybar/scripts/rofi.sh" "Wifi") || exit 0
[ -n "$choice" ] || exit 0

# Drop the marker column, then everything from the band column onwards.
ssid=$(printf '%s' "$choice" | sed 's/^..//; s/  *[0-9.]* GHz .*$//; s/ *$//')
[ -n "$ssid" ] || exit 0

if nmcli -t -f NAME connection show | grep -qxF "$ssid"; then
    nmcli -w "$CONNECT_TIMEOUT" connection up "$ssid" >/dev/null 2>&1 && exit 0
    notify-send "Wifi" "Échec de connexion à $ssid"
    exit 1
fi

case "$choice" in
    *" open "*)
        nmcli -w "$CONNECT_TIMEOUT" device wifi connect "$ssid" >/dev/null 2>&1
        ;;
    *)
        password=$("$HOME/.config/polybar/scripts/rofi.sh" --password "Mot de passe $ssid") || exit 0
        [ -n "$password" ] || exit 0
        nmcli -w "$CONNECT_TIMEOUT" device wifi connect "$ssid" password "$password" >/dev/null 2>&1
        ;;
esac || {
    notify-send "Wifi" "Échec de connexion à $ssid"
    exit 1
}
