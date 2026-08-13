# 🧊 Polybar

_Status bar for **[i3](https://i3wm.org)**._

<p align="center">
  <img src=".github/bar2.png" alt="Polybar, left half" title="Polybar">
  <img src=".github/bar1.png" alt="Polybar, right half" title="Polybar">
</p>

<p align="center">
<img src="https://img.shields.io/badge/Polybar-3.7.1+-4081F2?logo=linux&logoColor=white" alt="Polybar"> <img src="https://img.shields.io/badge/WM-i3-98C379?logo=i3&logoColor=white" alt="i3"> <img src="https://img.shields.io/badge/Shell-POSIX-D19A66?logo=gnubash&logoColor=white" alt="POSIX shell"> <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?logo=opensourceinitiative&logoColor=white" alt="License"></a>
</p>

---

## 🖱️ Interactions

| **Module**    | **Left**          | **Middle**       | **Right**        | **Scroll**      |
| ------------- | ----------------- | ---------------- | ---------------- | --------------- |
| Logo          | Application menu  | -                | -                | -               |
| Spotify       | Play / pause      | Focus the window | Focus the window | Previous / next |
| Disk          | File manager      | -                | -                | -               |
| Wifi          | Network picker    | -                | -                | -               |
| VPN           | Toggle the tunnel | -                | -                | -               |
| Notifications | Pause / resume    | -                | -                | -               |
| Microphone    | Mute              | pavucontrol      | Pick the device  | -               |
| Volume        | Mute              | pavucontrol      | Pick the device  | Volume          |
| Backlight     | -                 | -                | -                | Brightness      |
| Power         | Power menu        | -                | -                | -               |

## 📦 Install

The repository is the configuration folder itself.

```bash
git clone https://github.com/k44sh/polybar.git ~/.config/polybar
```

```bash
# Debian, Ubuntu
sudo apt install polybar i3-wm rofi pulseaudio-utils network-manager libnotify-bin
sudo apt install dunst playerctl curl nemo pavucontrol i3lock-fancy

# Arch
sudo pacman -S polybar i3-wm rofi libpulse networkmanager libnotify
sudo pacman -S dunst playerctl curl nemo pavucontrol ttf-hack-nerd i3lock-fancy
```

```bash
# Fonts
mkdir -p ~/.local/share/fonts
curl -fLo /tmp/Hack.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip
unzip -o /tmp/Hack.zip -d ~/.local/share/fonts/
fc-cache -f
```

**Start it from i3**, in `~/.config/i3/config`:

```
exec_always --no-startup-id $HOME/.config/polybar/launcher
```

One file to edit, [`machine.env`](machine.env). The launcher exports it, so the ini files and the scripts share the same values.

| **Variable**         | **Role**                   | **How to find it**              |
| -------------------- | -------------------------- | ------------------------------- |
| `POLYBAR_WLAN0`      | Wireless interface         | `ip -o link show`               |
| `POLYBAR_ETH0`       | Wired interface            | `ip -o link show`               |
| `POLYBAR_VPN0`       | VPN NetworkManager profile | `nmcli connection show`         |
| `POLYBAR_BATTERY`    | Battery                    | `ls /sys/class/power_supply`    |
| `POLYBAR_BACKLIGHT`  | Backlight card             | `ls /sys/class/backlight`       |
| `POLYBAR_THERMAL`    | CPU thermal zone           | `cat /sys/class/thermal/*/type` |
| `POLYBAR_DATA_MOUNT` | Second filesystem watched  | `lsblk`                         |

Network links use numbered slots, `wlan0` `eth0` `vpn0`. To add one, declare the next variable and copy its module block in `config.d/networking.ini`.

A VPN is named by its NetworkManager profile. The device it runs on is asked to NetworkManager, so WireGuard and OpenVPN behave the same.
