#!/usr/bin/env bash

# Define the list of web apps
declare -A APPS=(
  ["WhatsApp Web"]="https://web.whatsapp.com"
  ["Claude"]="https://claude.ai"
)

CHROME="/opt/google/chrome/google-chrome"
PROFILE="Profile 1"
DESKTOP_DIR="$HOME/.local/share/chezmoi/private_dot_local/share/applications"

for NAME in "${!APPS[@]}"; do
  URL="${APPS[$NAME]}"
  SAFE_NAME=$(echo "$NAME" | tr ' ' '_' | tr -dc 'A-Za-z0-9_-')
  DESKTOP_FILE="$DESKTOP_DIR/chrome-$SAFE_NAME.desktop"

  if [[ -f "$DESKTOP_FILE" ]]; then
    echo "Desktop file for $NAME already exists, skipping..."
    continue
  fi

  echo "Creating desktop file for $NAME..."

  # Create a simple portable desktop file
  cat > "$DESKTOP_FILE" <<EOF
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Name=$NAME
Exec=sh -c "$CHROME --profile-directory='$PROFILE' --class='$SAFE_NAME' --app='$URL'"
Icon=web-browser
StartupWMClass=$SAFE_NAME
Terminal=false
EOF
done
