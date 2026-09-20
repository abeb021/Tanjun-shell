#!/bin/bash
set -euo pipefail

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/tanjun/config.json"
IFS=$'\t' read -r DEVICE_MAC DEVICE_NAME < <(python3 - "$CFG" <<'PY'
import json, sys
path = sys.argv[1]
try:
    data = json.load(open(path, encoding="utf-8"))
except Exception:
    data = {}
svc = data.get("services") or {}
mac = str(svc.get("budsMac") or "").strip()
name = str(svc.get("budsName") or "buds").strip() or "buds"
print(f"{mac}\t{name}")
PY
)

if [[ -z "${DEVICE_MAC:-}" ]]; then
    notify-send -t 2500 -a "Bluetooth" "No buds MAC" "Set it in Settings → devices." -i dialog-error
    exit 1
fi

info=$(bluetoothctl info "$DEVICE_MAC" 2>/dev/null || true)
if echo "$info" | grep -q "Connected: yes"; then
    echo "Headphones $DEVICE_NAME ($DEVICE_MAC) are connected. Disconnecting..."
    bluetoothctl disconnect "$DEVICE_MAC"
    notify-send -t 4000 -a "Bluetooth" "Headphones Disconnected" "Disconnected from $DEVICE_NAME." -i audio-headphones
else
    echo "Headphones $DEVICE_NAME ($DEVICE_MAC) are not connected. Connecting..."
    if bluetoothctl connect "$DEVICE_MAC"; then
        notify-send -t 2500 -a "Bluetooth" "Headphones Connected" "Connected to $DEVICE_NAME." -i audio-headphones
    else
        notify-send -t 2500 -a "Bluetooth Error" "Connection Failed" "Failed to connect to $DEVICE_NAME. Please ensure headphones are on and in pairing mode." -i dialog-error
    fi
fi
