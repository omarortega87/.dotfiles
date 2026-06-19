#!/bin/bash
STATE_FILE="/tmp/waybar-system-stats-toggle"

if [ ! -f "$STATE_FILE" ]; then
  echo "compact" > "$STATE_FILE"
fi

if [ "$1" = "toggle" ]; then
  CURRENT=$(cat "$STATE_FILE")
  if [ "$CURRENT" = "compact" ]; then
    echo "expanded" > "$STATE_FILE"
  else
    echo "compact" > "$STATE_FILE"
  fi
  pkill -35 waybar
  exit 0
fi

STATE=$(cat "$STATE_FILE")

CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1)
[ -z "$CPU" ] && CPU=0
MEM=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
FAN=$(cat /sys/class/hwmon/hwmon5/fan1_input 2>/dev/null || echo "0")

if [ "$STATE" = "expanded" ]; then
  TEXT="CPU ${CPU}% | MEM ${MEM}% | ${FAN} RPM"
  CLASS="expanded"
else
  TEXT="󰍛"
  CLASS="compact"
fi

echo "{\"text\": \"$TEXT\", \"class\": \"$CLASS\"}"
