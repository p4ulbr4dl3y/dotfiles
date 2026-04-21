#!/bin/bash

# Menu options (icons only)
shutdown="⏻"
reboot="󰑓"
logout="󰗽"

# Build list (order: shutdown, reboot, logout)
options="$shutdown\n$reboot\n$logout"

# CSS overrides specifically for HORIZONTAL menu
theme_str='
window {
    width: 250px;          /* Reduced total window width (was 450px) */
    padding: 10px;         /* Reduced edge padding (was 20px) */
    border-radius: 12px;   /* Slightly smaller rounding (was 20px) */
}
inputbar {
    enabled: false;        /* Completely hide search bar */
}
listview {
    columns: 3;            /* THREE columns (arranged horizontally) */
    lines: 1;              /* ONE row */
    spacing: 10px;         /* Reduced spacing between tiles (was 20px) */
    scrollbar: false;
}
element {
    padding: 15px 0px;     /* Reduced button height (was 30px) */
    border-radius: 8px;    /* Tile rounding (was 15px) */
}
element-text {
    font: "JetBrainsMono NF 24"; /* Reduced icon size (was 40) */
    horizontal-align: 0.5;       /* Center horizontally */
    vertical-align: 0.5;         /* Center vertically */
    cursor: pointer;
}
'

# Call rofi
chosen="$(echo -e "$options" | rofi -dmenu -theme ~/.config/rofi/hyprland.rasi -theme-str "$theme_str")"

# Execute command based on selection
case $chosen in
    $shutdown)
        systemctl poweroff
        ;;
    $reboot)
        systemctl reboot
        ;;
    $logout)
        hyprctl dispatch exit
        ;;
esac
