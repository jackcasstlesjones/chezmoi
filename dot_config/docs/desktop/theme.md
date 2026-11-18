# Theme pipeline
Source of truth: pywal. Desktop palette ~/.cache/wal; lock palette separate (lock.md).
Wallpaper: ~/.config/waybar/scripts/wallpaper-theme.sh
- no args: fzf+kitty picker (class wallpaper-picker). `pick`, `preview F`, `apply F` (no picker; used by hypr-settings), `lock F` (-> lock.sh prepare).
- fixed themes: ~/.config/wal/wallpaper-themes (`<file> <pywal theme>`), shared w/ lock.sh; else `wal -i`.
- edited by hypr-settings Look (`c`): dropdown of all dark + reachable light themes (light retried w/ `wal -l` in both scripts), preview card (image palettes via separate PYWAL_CACHE_DIR, cached ~/.cache/hypr-settings/palettes), writes chezmoi source + `chezmoi apply --force`, deletes ~/.cache/lock-wal/<file>.conf.
- live mode (list open on the desktop's wallpaper): 250ms debounce -> `wal --theme X -n -e -q` (recolours terminals), borders via `hyprctl eval hl.config({general={col=...}})`, SIGUSR2 waybar. Snapshot colors.json -> ~/.cache/hypr-settings/live-restore.json; close w/o pick = `wal --theme <snapshot>`; pick = full `wallpaper-theme.sh apply`.
- then: wal-qt6ct.py; `awww img` random transition from (wipe wave grow outer any) + random angle; SIGUSR2 waybar; hyprctl reload; makoctl reload.
awww (pkg awww, was swww): `awww-daemon` in autostart, restores last image per monitor. hyprpaper retired (create_hyprpaper.conf kept).
pywal consumers: hypr borders (config/colors.lua parses colors-hyprland.conf), waybar, mako, kitty, fuzzel (template colors-fuzzel.ini), qt6ct, hypr-settings/media-controller/desktop-menu (read colors.json).
Qt: scripts/wal-qt6ct.py -> ~/.cache/wal/colors-qt6ct.conf; ~/.config/qt6ct/qt6ct.conf (unmanaged) color_scheme_path points there, style Fusion. env QT_QPA_PLATFORMTHEME=qt6ct. qt6ct-kde is AUR: rebuild after every qt6-base minor bump (`yay -S --rebuild qt6ct-kde`) or Qt silently ignores it (check: `qtdiag6 | grep -A2 Theme`, qt6ct must be in "available").
GTK: not pywal (tried colors.css generation; reverted). Breeze-Dark + breeze-dark icons via hypr-settings Appearance. ~/.config/gtk-3.0/colors.css = KDE-generated *_breeze names Breeze GTK reads.
Style tokens (match Hyprland look.lua): rounding 2px, borders 3px, active=color11 (accent), inactive=color8, surface=color0, ok=color2, urgent=color1, gaps 10/20, font JetBrains Mono. Icons: Font Awesome 7 Free Solid.
Gotcha: never write PUA glyphs via heredoc (got stripped -> empty strings; waybar hides modules w/ empty format). Use escapes ( in JSON, chr(0xf002) in py).
