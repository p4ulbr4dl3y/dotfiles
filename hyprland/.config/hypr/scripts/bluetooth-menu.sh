#!/usr/bin/env bash
#
# Bluetooth Rofi Menu - adaptation of nickclyde/rofi-bluetooth
# For Hyprland with theme from hyprland.rasi
#

set -e

ROFI_THEME="$HOME/.config/rofi/hyprland.rasi"

# Constants
divider="---------"
goback=" Back"

# Notifications
notify() {
    local urgency="$1"
    local title="$2"
    local message="$3"
    notify-send -u "$urgency" "Bluetooth" "$message"
}

# Checks if bluetooth controller is powered on
power_on() {
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        return 0
    else
        return 1
    fi
}

# Toggles power state
toggle_power() {
    if power_on; then
        bluetoothctl power off
        show_menu
    else
        if rfkill list bluetooth 2>/dev/null | grep -q 'blocked: yes'; then
            rfkill unblock bluetooth && sleep 2
        fi
        bluetoothctl power on
        sleep 1
        show_menu
    fi
}

# Checks if controller is scanning for new devices
scan_on() {
    if bluetoothctl show 2>/dev/null | grep -q "Discovering: yes"; then
        return 0
    else
        return 1
    fi
}

# Toggles scanning state
toggle_scan() {
    if scan_on; then
        bluetoothctl scan off
        show_menu
    else
        bluetoothctl scan on &
        sleep 5
        bluetoothctl scan off
        show_menu
    fi
}

# Checks if controller is able to pair to devices
pairable_on() {
    if bluetoothctl show 2>/dev/null | grep -q "Pairable: yes"; then
        return 0
    else
        return 1
    fi
}

# Toggles pairable state
toggle_pairable() {
    if pairable_on; then
        bluetoothctl pairable off
        show_menu
    else
        bluetoothctl pairable on
        show_menu
    fi
}

# Checks if controller is discoverable by other devices
discoverable_on() {
    if bluetoothctl show 2>/dev/null | grep -q "Discoverable: yes"; then
        return 0
    else
        return 1
    fi
}

# Toggles discoverable state
toggle_discoverable() {
    if discoverable_on; then
        bluetoothctl discoverable off
        show_menu
    else
        bluetoothctl discoverable on
        show_menu
    fi
}

# Checks if a device is connected
device_connected() {
    local mac="$1"
    local device_info
    device_info=$(bluetoothctl info "$mac" 2>/dev/null)
    if echo "$device_info" | grep -q "Connected: yes"; then
        return 0
    else
        return 1
    fi
}

# Toggles device connection
toggle_connection() {
    local mac="$1"
    local name="$2"

    if device_connected "$mac"; then
        bluetoothctl disconnect "$mac"
    else
        if bluetoothctl connect "$mac" 2>&1 | grep -q "Connection successful\|connected"; then
            notify low "Bluetooth" "Connected: $name"
        else
            notify critical "Bluetooth" "Error: $name"
        fi
    fi
    device_menu "$device"
}

# Checks if a device is paired
device_paired() {
    local mac="$1"
    local device_info
    device_info=$(bluetoothctl info "$mac" 2>/dev/null)
    if echo "$device_info" | grep -q "Paired: yes"; then
        return 0
    else
        return 1
    fi
}

# Toggles device paired state
toggle_paired() {
    local mac="$1"
    local name="$2"

    if device_paired "$mac"; then
        bluetoothctl remove "$mac"
    else
        if bluetoothctl pair "$mac" 2>&1 | grep -q "Pairing successful\|paired"; then
            notify low "Bluetooth" "Paired: $name"
        else
            notify critical "Bluetooth" "Error: $name"
        fi
    fi
    device_menu "$device"
}

# Checks if a device is trusted
device_trusted() {
    local mac="$1"
    local device_info
    device_info=$(bluetoothctl info "$mac" 2>/dev/null)
    if echo "$device_info" | grep -q "Trusted: yes"; then
        return 0
    else
        return 1
    fi
}

# Toggles device trusted state
toggle_trust() {
    local mac="$1"
    local name="$2"

    if device_trusted "$mac"; then
        bluetoothctl untrust "$mac"
    else
        bluetoothctl trust "$mac"
    fi
    device_menu "$device"
}

# A submenu for a specific device
device_menu() {
    local device="$1"

    # Get device name and mac address
    local device_name
    device_name=$(echo "$device" | cut -d ' ' -f 3-)
    local mac
    mac=$(echo "$device" | cut -d ' ' -f 2)

    # Build options
    local connected_label
    if device_connected "$mac"; then
        connected_label="[V] Connected"
    else
        connected_label="[X] Disconnected"
    fi

    local paired_label
    if device_paired "$mac"; then
        paired_label="[V] Paired"
    else
        paired_label="[X] Not paired"
    fi

    local trusted_label
    if device_trusted "$mac"; then
        trusted_label="[L] Trusted"
    else
        trusted_label="[U] Untrusted"
    fi

    local options="$connected_label\n$paired_label\n$trusted_label\n$divider\n$goback\nExit"

    # Open rofi menu, read chosen option
    local chosen
    chosen="$(echo -e "$options" | rofi -dmenu -theme "$ROFI_THEME" -p "$device_name" -i -selected-row 0)"

    # Match chosen option to command
    case "$chosen" in
        "" | "$divider")
            ;;
        "[V] Connected"|"[X] Disconnected")
            toggle_connection "$mac" "$device_name"
            ;;
        "[V] Paired"|"[X] Not paired")
            toggle_paired "$mac" "$device_name"
            ;;
        "[L] Trusted"|"[U] Untrusted")
            toggle_trust "$mac" "$device_name"
            ;;
        "$goback")
            show_menu
            ;;
    esac
}

# Opens a rofi menu with current bluetooth status
show_menu() {
    # Get menu options
    if power_on; then
        local power_label="[V] Bluetooth enabled"

        # Get devices
        local devices
        devices=$(bluetoothctl devices 2>/dev/null | grep Device | cut -d ' ' -f 3-)

        # Add connected status indicator
        local device_list=""
        while IFS= read -r device; do
            [ -z "$device" ] && continue
            local mac
            mac=$(bluetoothctl devices 2>/dev/null | grep "$device" | cut -d ' ' -f 2)
            local icon=" "
            if device_connected "$mac"; then
                icon=" [V] "
            fi
            device_list+="$icon$device\n"
        done <<< "$devices"

        # Get controller flags
        local scan_label
        if scan_on; then
            scan_label="[S] Scanning: on"
        else
            scan_label="[S] Scanning: off"
        fi

        local pairable_label
        if pairable_on; then
            pairable_label="[P] Pairable: on"
        else
            pairable_label="[P] Pairable: off"
        fi

        local discoverable_label
        if discoverable_on; then
            discoverable_label="[D] Discoverable: on"
        else
            discoverable_label="[D] Discoverable: off"
        fi

        local options="${device_list}$divider\n$power_label\n$scan_label\n$pairable_label\n$discoverable_label\nExit"
    else
        local power_label="[X] Bluetooth disabled"
        local options="$power_label\nExit"
    fi

    # Open rofi menu, read chosen option
    local chosen
    chosen="$(echo -e "$options" | rofi -dmenu -theme "$ROFI_THEME" -p "Bluetooth" -i -selected-row 0)"

    # Match chosen option to command
    case "$chosen" in
        "" | "$divider")
            ;;
        "[V] Bluetooth enabled"|"[X] Bluetooth disabled")
            toggle_power
            ;;
        "[S] Scanning: on"|"[S] Scanning: off")
            toggle_scan
            ;;
        "[D] Discoverable: on"|"[D] Discoverable: off")
            toggle_discoverable
            ;;
        "[P] Pairable: on"|"[P] Pairable: off")
            toggle_pairable
            ;;
        "Exit")
            exit 0
            ;;
        *)
            # Device selected - clean the name
            local clean_device
            clean_device=$(echo "$chosen" | sed 's/^\s\[V\]\s//;s/^\s\[X\]\s//;s/^\s//')
            local device_line
            device_line=$(bluetoothctl devices 2>/dev/null | grep "$clean_device")
            if [[ $device_line ]]; then
                device_menu "$device_line"
            fi
            ;;
    esac
}

# Main
show_menu
