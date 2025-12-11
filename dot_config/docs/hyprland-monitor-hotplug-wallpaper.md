# Hyprland Monitor Hotplug Wallpaper Issue

## Problem

When connecting/disconnecting/reconnecting external monitors, the desktop wallpaper and windows briefly disappear then "whoosh" back into view. This happens because:

1. Hyprland reconfigures the display layout when monitors are added/removed
2. hyprpaper doesn't immediately reload the wallpaper for the new monitor configuration
3. Window animations (`windowsIn` with bounce/slide effects) trigger as windows are remapped to the new display configuration

## Solutions

### Option 1: hyprland-monitor-attached (Recommended)

A dedicated Rust tool that listens to Hyprland's `monitoradded` and `monitorremoved` events and runs scripts.

**Installation:**
```bash
# Available in AUR or crates.io
paru -S hyprland-monitor-attached
# or
cargo install hyprland-monitor-attached
```

**Usage in hyprland.conf:**
```bash
exec-once = hyprland-monitor-attached /path/to/reload-wallpaper.sh
```

**Create reload script:**
```bash
#!/usr/bin/env bash
# ~/.config/scripts/reload-wallpaper.sh
sleep 0.5  # Give Hyprland time to reconfigure monitors
killall hyprpaper
hyprpaper &
```

### Option 2: Socket2 Event Listener (DIY)

Listen to Hyprland's event socket directly with a background script.

**Create monitor event listener:**
```bash
#!/usr/bin/env bash
# ~/.config/scripts/monitor-event-listener.sh

socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read line; do
    if [[ "$line" =~ "monitoradded" ]] || [[ "$line" =~ "monitorremoved" ]]; then
        sleep 0.5
        killall hyprpaper && hyprpaper &
    fi
done
```

**Add to hyprland.conf:**
```bash
exec-once = ~/.config/scripts/monitor-event-listener.sh
```

**Note:** Socket connection may terminate after workspace reloading.

### Option 3: udev Rules (Most Robust)

Monitor DRM (Direct Rendering Manager) events at the kernel level.

**Monitor DRM events:**
```bash
udevadm monitor -s drm -p
```

**Create udev rule:**
```
# /etc/udev/rules.d/95-monitor-hotplug.rules
ACTION=="change", SUBSYSTEM=="drm", RUN+="/usr/local/bin/reload-hyprpaper.sh"
```

**More complex setup but most reliable.**

### Option 4: hyprpaper IPC (Alternative)

Instead of killing hyprpaper, use IPC commands to reload wallpaper:

```bash
hyprctl hyprpaper reload
# or set wallpaper for specific monitor:
hyprctl hyprpaper wallpaper "DP-9,~/.config/wallpapers/city2.png"
```

## Related Issues

- Window animations (bounce/slide) make the "whooshing" effect more noticeable
- The delay is typically 0.5-1 second while hyprpaper catches up to monitor reconfiguration
- Issue also related to suspend/resume when external monitors are connected

## References

- [Hyprland Discussion #5644 - Monitor event scripts](https://github.com/hyprwm/Hyprland/discussions/5644)
- [hyprland-monitor-attached GitHub](https://github.com/coffebar/hyprland-monitor-attached)
- [hyprpaper Documentation](https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper/)
- [Using hyprctl Wiki](https://wiki.hypr.land/Configuring/Using-hyprctl/)
- [Hyprland Issue #1341 - monitoradded/removed events](https://github.com/hyprwm/Hyprland/issues/1341)

## Notes

- hyprpaper is IPC-controlled but doesn't automatically handle monitor hotplug events
- The socket2 approach is simpler but less reliable than udev
- Consider switching to `swww` (alternative wallpaper daemon) if issues persist
- The `.5s` sleep delay gives Hyprland time to reconfigure monitors before reloading wallpaper
