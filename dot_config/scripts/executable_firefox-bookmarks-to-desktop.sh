#!/usr/bin/env bash

# Firefox Bookmarks to Desktop Files
# Reads Firefox bookmarks and creates .desktop files for fuzzel

# Configuration
FIREFOX_PROFILE="$HOME/.mozilla/firefox/5d5r9hx4.default-release"
BOOKMARKS_DB="$FIREFOX_PROFILE/places.sqlite"
DESKTOP_DIR="$HOME/.local/share/applications/bookmarks"
ICON="applications-internet"

# Create desktop directory if it doesn't exist
mkdir -p "$DESKTOP_DIR"

# Check if Firefox database exists
if [ ! -f "$BOOKMARKS_DB" ]; then
    notify-send "Bookmark Sync" "Firefox bookmarks database not found"
    exit 1
fi

# Clean old bookmark desktop files (only those created by this script)
rm -f "$DESKTOP_DIR"/bookmark-*.desktop

# Query bookmarks and create desktop files
sqlite3 "$BOOKMARKS_DB" "
SELECT b.title, p.url
FROM moz_bookmarks b
JOIN moz_places p ON b.fk = p.id
WHERE b.type = 1
  AND b.title IS NOT NULL
  AND b.title != ''
  AND p.url NOT LIKE 'place:%'
ORDER BY b.title;
" | while IFS='|' read -r title url; do
    # Skip if empty
    [ -z "$title" ] && continue
    [ -z "$url" ] && continue

    # Sanitize filename (replace spaces and special chars with dashes)
    filename=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
    desktop_file="$DESKTOP_DIR/bookmark-${filename}.desktop"

    # Create desktop file
    cat > "$desktop_file" << EOF
[Desktop Entry]
Name=$title
Comment=Open bookmark: $url
Exec=firefox "$url"
Icon=$ICON
Type=Application
Categories=Network;WebBrowser;
Keywords=bookmark;firefox;
NoDisplay=false
EOF
done

# Count created files
count=$(ls -1 "$DESKTOP_DIR"/*.desktop 2>/dev/null | wc -l)
notify-send "Bookmark Sync" "Created $count bookmark launchers"
