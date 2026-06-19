#!/bin/bash

PROFILE_PATH="/sys/firmware/acpi/platform_profile"
CHOICES_PATH="/sys/firmware/acpi/platform_profile_choices"

if [[ ! -r "$PROFILE_PATH" ]]; then
    echo '{"text": "󰟢 N/A", "class": "na", "alt": "na"}'
    exit 0
fi

AVAILABLE=($(cat "$CHOICES_PATH"))
CURRENT=$(cat "$PROFILE_PATH")

ICONS=("cool" "balanced" "performance")
declare -A ICON_MAP LABEL_MAP
ICON_MAP=(["cool"]="" ["balanced"]="" ["performance"]="󰓅")
LABEL_MAP=(["cool"]="Cool" ["balanced"]="Balanced" ["performance"]="Perf")

case "$1" in
    next)
        for i in "${!AVAILABLE[@]}"; do
            if [[ "${AVAILABLE[$i]}" == "$CURRENT" ]]; then
                NEXT=${AVAILABLE[$(( (i + 1) % ${#AVAILABLE[@]} ))]}
                echo "$NEXT" | sudo tee "$PROFILE_PATH" > /dev/null
                break
            fi
        done
        ;;
    *)
        ICON="${ICON_MAP[$CURRENT]:-󰟢}"
        LABEL="${LABEL_MAP[$CURRENT]:-$CURRENT}"
        echo "{\"text\": \"${ICON} ${LABEL}\", \"class\": \"$CURRENT\", \"alt\": \"$CURRENT\"}"
        ;;
esac
