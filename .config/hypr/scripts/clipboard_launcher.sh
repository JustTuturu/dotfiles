#!/usr/bin/env bash
# clipboard_launcher.sh — clipboard history via cliphist + rofi

if ! command -v cliphist &>/dev/null; then
    notify-send "Error" "cliphist not found."
    exit 1
fi

selected=$(cliphist list | rofi -dmenu -p "Clipboard" -i)
[ -n "$selected" ] && echo "$selected" | cliphist decode | wl-copy
