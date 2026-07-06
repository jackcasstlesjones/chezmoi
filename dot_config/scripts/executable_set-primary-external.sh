#!/usr/bin/env bash
# Set the first connected non-eDP output as XWayland primary,
# so fullscreen games see the external monitor's mode list.
ext=$(xrandr 2>/dev/null | awk '/ connected/ && $1 !~ /^eDP/ {print $1; exit}')
if [ -z "$ext" ]; then
  echo "No external monitor connected" >&2
  exit 1
fi
xrandr --output "$ext" --primary
echo "Primary set to $ext"
