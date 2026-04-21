#!/usr/bin/env bash
#
# WiFi Rofi Menu - adaptation of wifimenu for Hyprland
# Based on: https://github.com/byapplets/wifimenu
#

set -e

ROFI_THEME="$HOME/.config/rofi/hyprland.rasi"

# Icons and labels
TAG_NOT_CONNECTED="󰤭 Not connected"
TAG_WIFI_DISABLE="󰤭 Disable WiFi"
TAG_WIFI_ENABLE="󱚽 Enable WiFi"
TAG_MANAGE_KNOWN="󱚾 Manage networks"
TAG_FORGET="󰜺 Forget network"
TAG_AUTOCONNECT_ON=" Auto-connect: "
TAG_AUTOCONNECT_OFF=" Auto-connect: "
TAG_BACK=" Back"
TAG_RESCAN=" Refresh"

# Get WiFi status
get_connection_status() {
    local status
    status=$(nmcli -g WIFI g)
    if [[ "$status" == "enabled" ]]; then
        WIFI_ENABLED=true
        TOGGLE="$TAG_WIFI_DISABLE"
    else
        WIFI_ENABLED=false
        TOGGLE="$TAG_WIFI_ENABLE"
    fi

    # Current connection
    CURRENT_SSID=$(nmcli -g NAME connection show --active 2>/dev/null | head -1)
    if [ -z "$CURRENT_SSID" ]; then
        CURRENT_SSID="$TAG_NOT_CONNECTED"
    fi
}

# Scan networks
scan_networks() {
    nmcli dev wifi rescan 2>/dev/null || true
    sleep 1
}

# Get list of networks
get_wifi_list() {
    nmcli -g SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null | \
        sort -t: -k2 -rn | \
        awk -F: '!seen[$1]++' | \
        head -20
}

# Format signal icon
get_signal_icon() {
    local signal=$1
    if [ "$signal" -gt 80 ]; then
        echo "󰤨"
    elif [ "$signal" -gt 60 ]; then
        echo "󰤥"
    elif [ "$signal" -gt 40 ]; then
        echo "󰤢"
    elif [ "$signal" -gt 20 ]; then
        echo "󰤟"
    else
        echo "󰤯"
    fi
}

# Main menu
show_main_menu() {
    local menu_items=()
    local current_row=0
    local selected_row=0

    if [ "$WIFI_ENABLED" = true ]; then
        # Current network
        menu_items+=("󰘾 $CURRENT_SSID")

        # List of available networks
        while IFS=: read -r ssid signal security; do
            [ -z "$ssid" ] && continue
            [ "$ssid" = "$CURRENT_SSID" ] && continue

            local icon=$(get_signal_icon "$signal")
            local sec_icon=""
            [ -n "$security" ] && sec_icon=" 󰒃"

            menu_items+=("$icon $ssid$sec_icon")
        done < <(get_wifi_list)

        # Additional options
        menu_items+=("")
        menu_items+=("$TAG_MANAGE_KNOWN")
        menu_items+=("$TOGGLE")
        menu_items+=("$TAG_RESCAN")

        selected_row=2
    else
        menu_items+=("$TAG_WIFI_ENABLE")
        selected_row=0
    fi

    # Show menu
    local choice
    choice=$(printf '%s\n' "${menu_items[@]}" | rofi -dmenu -theme "$ROFI_THEME" -p "WiFi" -i -selected-row "$selected_row")

    [ -z "$choice" ] && exit 0

    handle_main_choice "$choice"
}

# Handle main menu selection
handle_main_choice() {
    local choice="$1"

    case "$choice" in
        "$TAG_WIFI_ENABLE")
            nmcli radio wifi on
            sleep 0.5
            get_connection_status
            scan_networks
            show_main_menu
            ;;
        "$TAG_WIFI_DISABLE")
            nmcli radio wifi off
            get_connection_status
            show_main_menu
            ;;
        "$TAG_RESCAN")
            scan_networks
            get_connection_status
            show_main_menu
            ;;
        "$TAG_MANAGE_KNOWN")
            show_manage_known_menu
            ;;
        "󰘾 "*)
            # Already connected
            ;;
        *)
            # Connect to network
            local ssid=$(echo "$choice" | sed 's/^[󰤨󰤥󰤢󰤟󰤯] //' | sed 's/ 󰒃$//')
            connect_to_network "$ssid"
            ;;
    esac
}

# Menu of known networks
show_manage_known_menu() {
    local known_networks
    known_networks=$(nmcli -g NAME,TYPE connection show 2>/dev/null | grep ":wireless" | cut -d: -f1)

    if [ -z "$known_networks" ]; then
        show_main_menu
        return
    fi

    local menu_items=("$TAG_BACK")
    while IFS= read -r network; do
        [ -n "$network" ] && menu_items+=("$network")
    done <<< "$known_networks"

    local choice
    choice=$(printf '%s\n' "${menu_items[@]}" | rofi -dmenu -theme "$ROFI_THEME" -p "Networks" -i -selected-row 0)

    [ -z "$choice" ] && exit 0
    [ "$choice" = "$TAG_BACK" ] && show_main_menu

    show_network_submenu "$choice"
}

# Network control menu
show_network_submenu() {
    local network="$1"
    local autoconnect
    autoconnect=$(nmcli -g connection.autoconnect connection show "$network" 2>/dev/null)

    local autoconnect_label="$TAG_AUTOCONNECT_OFF"
    [ "$autoconnect" = "no" ] && autoconnect_label="$TAG_AUTOCONNECT_ON"

    local choice
    choice=$(printf "%s\n%s\n%s" "$TAG_BACK" "$TAG_FORGET" "$autoconnect_label" | \
        rofi -dmenu -theme "$ROFI_THEME" -p "$network" -i -selected-row 0)

    case "$choice" in
        "$TAG_BACK")
            show_manage_known_menu
            ;;
        "$TAG_FORGET")
            nmcli connection delete "$network"
            show_manage_known_menu
            ;;
        "$TAG_AUTOCONNECT_ON"|"$TAG_AUTOCONNECT_OFF")
            if [ "$autoconnect" = "no" ]; then
                nmcli connection modify "$network" connection.autoconnect yes
            else
                nmcli connection modify "$network" connection.autoconnect no
            fi
            show_network_submenu "$network"
            ;;
    esac
}

# Connect to network
connect_to_network() {
    local ssid="$1"

    # Check saved connections
    local saved=$(nmcli -g NAME connection show 2>/dev/null | grep -w "$ssid")

    if [ -n "$saved" ]; then
        # Saved network - just connect
        if nmcli connection up id "$ssid" 2>&1 | grep -q "successfully"; then
            notify-send -u low "WiFi" "✓ Connected: $ssid"
        else
            notify-send -u critical "WiFi" "✗ Error: $ssid"
        fi
    else
        # New network - authentication required
        local result
        result=$(nmcli dev wifi connect "$ssid" 2>&1)

        if echo "$result" | grep -q "successfully"; then
            notify-send -u low "WiFi" "✓ Connected: $ssid"
        elif echo "$result" | grep -qi "secret" || echo "$result" | grep -qi "password"; then
            # Password request
            local password
            password=$(echo "" | rofi -dmenu -theme "$ROFI_THEME" -p "Password for $ssid" -password)

            if [ -n "$password" ]; then
                if nmcli dev wifi connect "$ssid" password "$password" 2>&1 | grep -q "successfully"; then
                    notify-send -u low "WiFi" "✓ Connected: $ssid"
                else
                    notify-send -u critical "WiFi" "✗ Error: $ssid"
                fi
            fi
        else
            notify-send -u critical "WiFi" "✗ Error: $ssid"
        fi
    fi

    show_main_menu
}

# Entry point
main() {
    get_connection_status

    if [ "$WIFI_ENABLED" = true ]; then
        scan_networks
    fi

    show_main_menu
}

main
