# Custom Qt apps (PySide6, ~/.local/bin, single files, pywal-styled)
Shared pattern: stylesheet from ~/.cache/wal/colors.json; COLORS dict for QPainter; app_id via setDesktopFileName -> float rule in hypr/rules/windows.lua; Esc closes.

## hypr-settings [page]
Pages (PAGES): look appearance toggles bluetooth lock battery keybinds. Super+M opens it (system menu moved to Super+Shift+M); fuzzel entries Settings, Sound (=toggles). `hypr-settings keybinds` opens that page. Launcher entry "Settings".
- look: wallpaper grid (thumbs threaded; names in tooltips). Target Desktop/Lock screen/Both (`t` cycles); calls wallpaper-theme.sh apply|lock.
- appearance: GTK theme, icon theme, cursor, colour scheme. Writes gsettings org.gnome.desktop.interface + gtk-3.0/4.0 settings.ini (like nwg-look; xsettingsd.conf not written, daemon not running). Icon change restarts nm-applet; cursor -> `hyprctl setcursor`; autostart re-applies cursor from gsettings. 500ms debounce.
- toggles: Output/Input pickers (device_picker) + wifi(nmcli) bt(bluetoothctl) night light(hyprsunset 2000K) DND(makoctl mode do-not-disturb, defined in mako config) + volume(wpctl)/brightness(brightnessctl) sliders. Poll 3s. Night light/DND not persisted across login.
- lock: auto lock&suspend switch (start/stop hypridle, session only), lock/suspend minutes via scripts/hypridle-control.sh get|set (writes ~/.config/hypr/hypridle.conf, restarts hypridle if running; each step saves), shuffle switch, Lock now (lock.sh).
- battery: parses ~/.local/state/battery/battery.log; level/status/rate+time left; QPainter chart 12h/24h/7d; accent=on battery, ok=plugged, dashed fg@60% across gaps >15min (skipped if <8px); runs drawn as one QPainterPath (seams otherwise).
- keybinds: parses hypr/binds/*.lua (hyprctl binds -j gives only opaque ids). KEY_NAMES/COMMAND_LABELS/label_dispatcher map to friendly text; loops shown as ‹letter›; raw cmd in tooltip.
Keys: KeyNav app eventFilter (QWidget objects only; QWindow sees keys too). Tab/S-Tab, C-j/k pages; C-h sidebar, C-l page; page.nav(e): hjkl/arrows; RowNav mixin (controls list: j/k focus, h/l slider±5/spin±1/combo±1, Space/Enter activate); focused row gets property focused=true (accent border); `/` keybind search, Esc leaves it.
- bluetooth: power, scan (bluetoothctl --timeout 30 scan on), devices (busctl JSON), connect/pair(+trust)/forget via QProcess, busy labels; Forget -> in-window Confirm overlay (Cancel default, y/n/Esc).
Dropdowns: mouse/Enter apply immediately (activated); h/l steps debounced; refresh skips combos with pending timer (else old value re-applied).
Gotchas: Qt QSS can't style child QLabel by parent :hover; QSS can't draw knobs -> custom Switch(QCheckBox).paintEvent. Testing: QT_QPA_PLATFORM=offscreen (no platform theme loaded there); stub run/spawn/Popen narrowly.

## Popups: media-controller, audio-popup, bt-popup (QML layer-shell)
Launched by waybar on-click (custom/media, pulseaudio, bluetooth; right-click = pavucontrol / rfkill toggle). Each: PySide6 + QML (QQmlApplicationEngine.loadData, QML embedded in the .py) with layer-shell-qt's QML module `org.kde.layershell`; env QT_WAYLAND_SHELL_INTEGRATION=layer-shell set before Qt starts (strip it when spawning other Qt apps, else they become full-screen layers). Two surfaces: transparent full-screen catcher (LayerTop, exclusionZone -1, closes on any click) + popup (LayerOverlay, KeyboardInteractivityExclusive). Layer margins are measured below waybar's exclusive zone (top: 10 = just under bar). Anchors: media top-left, audio/bt top-right. Waybar can't report module coords (upstream issue #5410 open); tray menus only anchor because waybar draws them.
Why layer-shell: normal windows lose focus to follow_mouse=1 when the cursor moves. Widgets can't do layer-shell from Python (no bindings); QML can.
Single instance via QLocalServer (2nd launch closes 1st). Backend QObject: Properties must be declared in class body; QML reads context properties (player/backend/bt, theme dict from wal).
media-controller: playerctl -p spotify,%any poll 500ms; optimistic updates + 1.5s hold; Spotify MPRIS ignores Shuffle/LoopStatus -> hidden; MultiEffect blurred art backdrop.
audio-popup: lists outputs/inputs (hypr-settings audio_devices/set_audio_device: pactl, hides unplugged ports & monitors, moves streams), volume via wpctl. bt-popup: paired devices (hypr-settings bt_state via busctl GetManagedObjects), connect/disconnect via bluetoothctl, "Bluetooth settings" -> hypr-settings bluetooth.
Testing: never launch on the live session while the user types (exclusive keyboard grabs their input); test backends headless.

## desktop-menu
Right-click empty desktop (bind mouse:273 non_consuming in binds/apps.lua: skips if cursor over visible window or layer>=2). Left-click outside kills it (mouse:272 bind). Positioned at cursor via same rule-eval trick, no_anim. ITEMS list: terminal, files, fuzzel, wallpaper(settings look), settings, keybinds, screenshot(sleep .2 first), lock(lock.sh), wlogout.

## clip FILE...
Copies text/uri-list (file:// percent-encoded, CRLF) -> pastes as attachment. copy-latest-download.sh (Super+C) uses it.

## fuzzel
Styled like desktop-menu (fuzzel.ini + wal template colors-fuzzel.ini). No icons (mismatched). radius=0 required (1.15 paints padding in border colour if radius>0). dpi-aware=no (else first frame sized for laptop DPI, flashes 1.6x). Bind: plain `fuzzel`.
