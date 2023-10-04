#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
low="21"

# Check if 'acpi' or 'upower' command is available
getinfo () {
    if command -v acpi &> /dev/null; then
        battery_info=$(acpi -b)
        battery_percent=$(echo "$battery_info" | grep -P -o '[0-9]+(?=%)')
        if [[ $battery_info == *"Charging"* ]]; then
            charging="yes"
        elif [[ $battery_info == *"on-line"* ]]; then
            charging="no"
        else
            plug="yes"
        fi
    elif command -v upower &> /dev/null; then
        battery_info=$(upower -i $(upower -e | grep 'BAT'))
        battery_percent=$(echo "$battery_info" | grep "percentage" | awk '{print $2}' | tr -d '%')
        charging_state=$(echo "$battery_info" | grep "state" | awk '{print $2}')
        if [[ $charging_state == "charging" ]]; then
            charging="yes"
        elif [[ $charging_state == "discharging" ]]; then
            charging="no"
        else
            plug="yes"
        fi
    else
        notify-send "Error" "Neither 'acpi' nor 'upower' is available. Install one of them."
        exit 1
    fi
}

if [ "$1" = "1" ]; then
    while true; do
        plug="no"
        getinfo
        if [ "$charging" = "yes" ]; then
            if [ ! -f "$DIR/.charging" ]; then
                touch $DIR/.charging
                notify-send -i "$HOME/.local/share/dunst/charging.png" -u normal "Battery" "Charging Connected" -t 2000 --replace-id=555 -r 1 
            elif [ -f "$DIR/.low" ]; then
                rm -rf $DIR/.low
            fi    
	    elif [ "$plug" = "yes" ]; then
            if [ ! -f "$DIR/.plug" ]; then
                touch $DIR/.plug
                notify-send -i "$HOME/.local/share/dunst/power-plugin.png" -u normal "Battery" "Plugin not charging.." -t 2000 --replace-id=555 -r 1 
            elif [ -f "$DIR/.low" ]; then
                rm -rf $DIR/.low
            fi
        elif [ "$charging" = "no" ]; then
            if [ -f "$DIR/.charging" ]; then
                rm -rf $DIR/.charging
                notify-send -i "$HOME/.local/share/dunst/charging.png" -u normal "Battery" "Charging Disconnected" -t 2000 --replace-id=555 -r 1 
            elif [ "$battery_percent" -lt "$low" ]; then
                if [ ! -f "$DIR/.low" ]; then
                    touch $DIR/.low
                    notify-send -i "$HOME/.local/share/dunst/battery-warning.png" -u critical "Battery" "battery low ($battery_percent)" -t 2000 --replace-id=555 -r 1 
                fi
            elif [ "$battery_percent" -ge "$low" ]; then
                if [ -f "$DIR/.low" ]; then
                    rm -rf $DIR/.low
                fi
            fi
        elif [ "$plug" = "no" ]; then
            if [ -f "$DIR/.plug" ]; then
                rm -rf $DIR/.plug
                notify-send -i "$HOME/.local/share/dunst/power-plugin.png" -u normal "Battery" "Plugin Disconnected" -t 2000 --replace-id=555 -r 1 
            fi
        fi
        sleep 1
    done
elif [ "$1" = "2" ]; then
    while true; do
        plug="no"
        getinfo
        if [ "$charging" = "no" ]; then
            if [ "$plug" = "no" ]; then
                if [ "$battery_percent" -lt "$low" ]; then
                    notify-send -i "$HOME/.local/share/dunst/battery-warning.png" -u critical "Battery" "battery low ($battery_percent)" -t 2000 --replace-id=555 -r 1 
                fi
            fi
	    fi
        sleep 600
    done
fi