#!/usr/bin/env bash
# Same timeouts as the Hyprland idle file: dim 2m, lock 5m, DPMS 10m, suspend 15m, hibernate 30m.
exec swayidle -w \
  timeout 120 'brightnessctl -s set 30%' \
    resume 'brightnessctl -r' \
  timeout 300 'quickshell ipc --any-display call tanjun lock' \
  timeout 600 'niri msg action power-off-monitors' \
    resume 'niri msg action power-on-monitors && brightnessctl -r' \
  timeout 900 'systemctl suspend' \
  timeout 1800 'systemctl hibernate' \
  before-sleep 'quickshell ipc --any-display call tanjun lock'
