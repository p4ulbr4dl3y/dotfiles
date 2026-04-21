#!/bin/bash

PROXY_PORT=20170
CHECK_URL="https://www.google.com"
TIMEOUT=2

# Иконки (Nerd Fonts)
ICON_CONNECTED="󰦝"    # Shield check
ICON_DISCONNECTED="󰒙" # Shield off

if ! systemctl is-active --quiet v2raya; then
    echo "{\"text\": \"$ICON_DISCONNECTED\", \"alt\": \"stopped\", \"tooltip\": \"Stopped\", \"class\": \"stopped\"}"
    exit 0
fi

if curl -s --socks5-hostname 127.0.0.1:$PROXY_PORT "$CHECK_URL" --connect-timeout $TIMEOUT > /dev/null; then
    echo "{\"text\": \"$ICON_CONNECTED\", \"alt\": \"connected\", \"tooltip\": \"Connected\", \"class\": \"connected\"}"
else
    echo "{\"text\": \"$ICON_DISCONNECTED\", \"alt\": \"disconnected\", \"tooltip\": \"Disconnected\", \"class\": \"disconnected\"}"
fi
