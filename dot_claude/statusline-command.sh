#!/usr/bin/env bash
# Claude Code status line — p10k-style with Nord colour palette
# Segments: Dir > Model > Usage limit bar
# Arrows: literal '>' chevrons, no Powerline glyphs required.

input=$(cat | tee /tmp/claude-statusline-input.json)

# ── Raw data ──────────────────────────────────────────────────────────────────
cwd=$(echo "$input"       | jq -r '.cwd // .workspace.current_dir // empty')
model=$(echo "$input"     | jq -r '.model.display_name // empty')
five_hr=$(echo "$input"   | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
five_hr_resets_raw=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

# ── Rate-limit persistence ─────────────────────────────────────────────────────
RATE_CACHE=/tmp/claude-rate-limits-cache.json

if [ -n "$five_hr" ]; then
  printf '{"five_hr":"%s","seven_day":"%s","five_hr_resets":"%s"}\n' \
    "$five_hr" "$seven_day" "$five_hr_resets_raw" > "$RATE_CACHE"
elif [ -f "$RATE_CACHE" ]; then
  five_hr=$(jq -r '.five_hr // empty'          < "$RATE_CACHE")
  seven_day=$(jq -r '.seven_day // empty'       < "$RATE_CACHE")
  five_hr_resets_raw=$(jq -r '.five_hr_resets // empty' < "$RATE_CACHE")
fi

# ── Path: basename only ───────────────────────────────────────────────────────
if [ -z "$cwd" ]; then
  cwd="$(pwd)"
fi
short_cwd="${cwd##*/}"

# ── Model: first word only ────────────────────────────────────────────────────
model_short="${model%% *}"

# ── ANSI helpers ──────────────────────────────────────────────────────────────
fg() { printf '\033[38;5;%sm' "$1"; }
bg() { printf '\033[48;5;%sm' "$1"; }
reset=$(printf '\033[0m')
bold=$(printf '\033[1m')

# ── Nord palette (256-colour approximations) ─────────────────────────────────
# Polar Night : 236 #2e3440 · 238 #434c5e · 240 #4c566a
# Snow Storm  : 253 #d8dee9 · 255 #eceff4
# Frost       : 109 #8fbcbb · 110 #88c0d0 ·  67 #81a1c1 ·  60 #5e81ac
# Aurora      : 131 #bf616a · 173 #d08770 · 222 #ebcb8b · 108 #a3be8c · 139 #b48ead

BG_DIR=60     ; FG_DIR=255    # Nord deep-blue frost, snow text
BG_MODEL=139  ; FG_MODEL=236  # Nord purple aurora, polar-night text
BG_USAGE=131  ; FG_USAGE=255  # Nord red aurora, snow text (5h)
BG_WEEK=173   ; FG_WEEK=236   # Nord orange aurora, polar-night text (7d)

# Powerline right chevron (U+E0B0) — same glyph lualine uses for section separators.
ARROW=$(printf '\xee\x82\xb0')

# ── Segment builder ───────────────────────────────────────────────────────────
seg_texts=()
seg_bgs=()
seg_fgs=()

add_segment() {
  local text="$1" bg_c="$2" fg_c="$3"
  seg_texts+=("$text")
  seg_bgs+=("$bg_c")
  seg_fgs+=("$fg_c")
}

# ── Segment: Directory ────────────────────────────────────────────────────────
add_segment " ${short_cwd} " "$BG_DIR" "$FG_DIR"

# ── Segment: Model ────────────────────────────────────────────────────────────
if [ -n "$model_short" ]; then
  add_segment " ${model_short} " "$BG_MODEL" "$FG_MODEL"
fi

# ── Segment: Account usage limit (5-hour rolling window) ─────────────────────
five_hr_resets="$five_hr_resets_raw"
if [ -n "$five_hr" ]; then
  pct_int=$(printf '%.0f' "$five_hr")

  reset_label=""
  if [ -n "$five_hr_resets" ] && [ "$pct_int" -ge 70 ]; then
    now=$(date +%s)
    diff=$(( five_hr_resets - now ))
    if [ "$diff" -gt 0 ]; then
      total_mins=$(( diff / 60 ))
      hrs=$(( total_mins / 60 ))
      mins=$(( total_mins % 60 ))
      if [ "$hrs" -gt 0 ]; then
        reset_label=" (${hrs}h ${mins}m)"
      else
        reset_label=" (resets in ${mins}m)"
      fi
    fi
  fi

  add_segment " ${pct_int}%${reset_label} " "$BG_USAGE" "$FG_USAGE"
fi

# ── Segment: Account usage limit (7-day rolling window) ──────────────────────
if [ -n "$seven_day" ]; then
  seven_int=$(printf '%.0f' "$seven_day")
  add_segment " 7d ${seven_int}% " "$BG_WEEK" "$FG_WEEK"
fi

# ── Render ────────────────────────────────────────────────────────────────────
count=${#seg_texts[@]}
output=""

for i in "${!seg_texts[@]}"; do
  this_bg="${seg_bgs[$i]}"
  this_fg="${seg_fgs[$i]}"
  text="${seg_texts[$i]}"

  output+="$(bg "$this_bg")$(fg "$this_fg")${bold}${text}${reset}"

  next_i=$(( i + 1 ))
  if [ "$next_i" -lt "$count" ]; then
    next_bg="${seg_bgs[$next_i]}"
    output+="$(bg "$next_bg")$(fg "$this_bg")${ARROW}${reset}"
  else
    output+="$(fg "$this_bg")${ARROW}${reset}"
  fi
done

printf '%s' "$output"
