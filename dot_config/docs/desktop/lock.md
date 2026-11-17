# Lock screen (uncommitted as of 2026-11-17)
All routes -> ~/.config/scripts/lock.sh: hypridle lock_cmd (before_sleep -> loginctl lock-session), Super+Shift+L, desktop-menu, system-menu.sh, hypr-settings.
Prepared ahead (locking must be instant, e.g. pre-suspend):
- ~/.local/state/hypr/lock-wallpaper -> image (hyprlock background path; libmagic detects format, no ext needed)
- ~/.local/state/hypr/lock-colors.conf -> ~/.cache/lock-wal/<file>.conf (hyprlock `source`)
- ~/.local/state/hypr/lock-shuffle exists => after unlock, `prepare` random image (not current).
`lock.sh prepare [FILE]`: palette = `PYWAL_CACHE_DIR=tmp wal (--theme T | -i img) -n -s -t -e -q` (pywal ignores XDG_CACHE_HOME!), copy rendered template colors-hyprlock.conf, lowercase hex; cached per image (~0.2s first time).
hyprlock.conf: defines $lock_text/$lock_dim/$lock_accent/$lock_warn/$lock_urgent defaults then sources palette; clock=accent; bg blur_passes 2, blur_size 6, brightness 0.7.
hypridle.conf is chezmoi create_ (machine-owned after creation): edit both create_hypridle.conf and live file.
