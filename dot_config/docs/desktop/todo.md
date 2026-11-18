# TODO

## Centralise design tokens (radius, border, glass, gaps, font)
Problem: one design change (e.g. 10px corners) = hand edits in ~12 files / 7 formats: hypr look.lua, waybar styles/*.css, swayosd style.css, fuzzel.ini, hypr-settings stylesheet (`r = "2px"`), audio/bt/media/calc-popup QML, desktop-menu, hyprlock.conf, mako config. Each has a "matches look.lua" comment.
Plan (agreed, not started): chezmoi templating, not pywal (pywal = colours only, regenerates per wallpaper; tokens change rarely, belong in repo).
- `.chezmoidata/theme.toml`: radius, radius_inner (store explicitly; inner = outer - inset), border, glass (0.75), gap_in/gap_out, font, font_size.
- static configs -> `.tmpl` using `{{ .theme.radius }}` (look.lua, waybar css, fuzzel.ini, swayosd css, hyprlock.conf, mako config).
- runtime apps (hypr-settings, desktop-menu, QML popups) read generated `~/.config/theme/tokens.json` (itself a .tmpl).
- Exceptions: fuzzel radius must stay 0 (1.15 bug: paints padding in border colour); hyprlock card keeps its own big rounding (20).
- Do as 2 commits: (1) templates w/ current values, verify `chezmoi diff` empty; (2) then the rounding experiment (10px windows, waybar pills 10 / buttons 4 concentric, popups bg rect radius 10 w/ transparent Window, media backdrop masked) = change one number.
