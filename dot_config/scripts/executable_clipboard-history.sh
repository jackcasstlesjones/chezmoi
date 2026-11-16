#!/bin/bash
# Clipboard history picker with a preview pane (images drawn with kitty icat).
#   no args:     open the picker in a floating kitty window; Enter pastes the entry
#   pick:        run the picker in the current terminal
#   preview ID:  draw cliphist entry ID in fzf's preview pane

image() {
    # sed: fzf's documented fix so icat's trailing line doesn't scroll the pane
    kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin="$1" \
        --place="${FZF_PREVIEW_COLUMNS}x$((FZF_PREVIEW_LINES - 1))@0x0" "${@:2}" |
        sed '$d' | sed $'$s/$/\e[m/'
}

decode() { printf '%s\t\n' "$1" | cliphist decode; }

uri_path() {
    python3 -I -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1].strip()[7:]))' "$1"
}

# cliphist list -> "ID<tab>pretty label" with ANSI colours
FORMAT='
import sys, re, os, urllib.parse
dim, blue, green, yellow, off = "\033[90m", "\033[34m", "\033[32m", "\033[33m", "\033[0m"
home = os.path.expanduser("~")
for line in sys.stdin:
    id_, _, text = line.rstrip("\n").partition("\t")
    m = re.match(r"\[\[ binary data (.+?) (\w+) (\d+)x(\d+) \]\]", text)
    if m:
        size, fmt, w, h = m.groups()
        label = f"{blue}{off}  Image  {dim}{w}×{h} · {fmt} · {size}{off}"
    elif text.startswith("[[ binary data"):
        label = f"{blue}{off}  Binary  {dim}{text[15:-3]}{off}"
    elif text.startswith("file://") and "\n" not in text:
        path = urllib.parse.unquote(text.split()[0][7:])
        folder = os.path.dirname(path).replace(home, "~", 1)
        label = f"{green}{off}  {os.path.basename(path)}  {dim}{folder}{off}"
    elif re.match(r"https?://\S+$", text):
        label = f"{yellow}{off}  {text}"
    else:
        label = f"{dim}{off}  " + " ".join(text.split())
    print(f"{id_}\t{label}")
'

case "${1:-}" in
    pick) ;;
    preview)
        mime="$(decode "$2" | file -b --mime-type -)"
        if [[ "$mime" == image/* ]]; then
            decode "$2" | image yes
            exit
        fi
        content="$(decode "$2")"
        if [[ "$content" == file://* && "$content" != *$'\n'?* ]]; then
            path="$(uri_path "$content")"
            if [[ "$(file -b --mime-type "$path" 2>/dev/null)" == image/* ]]; then
                image no "$path"
            else
                printf '\e[1m%s\e[0m\n\e[90m%s\e[0m\n\n' "$(basename "$path")" "$(dirname "$path")"
                file -b "$path" 2>/dev/null || echo "File no longer exists"
            fi
        else
            printf '%s\n' "$content"
        fi
        exit
        ;;
    *) exec kitty --class clipboard-history -o window_padding_width=10 "$0" pick ;;
esac

id=$(cliphist list | head -n 20 | python3 -I -c "$FORMAT" |
    fzf --ansi --no-sort --exact --delimiter=$'\t' --with-nth=2 --accept-nth=1 \
        --prompt=$'\uf002  ' --pointer='▌' --ellipsis='…' --info=inline-right --no-separator --no-scrollbar --gutter=' ' --highlight-line \
        --list-border=rounded --list-label=' Clipboard ' \
        --preview "\"$0\" preview {1}" \
        --preview-window=right,55%,wrap --preview-border=rounded --preview-label=' Preview ' \
        --color='fg:-1,bg:-1,fg+:-1:bold,bg+:-1,hl:4,hl+:4:bold,pointer:4,prompt:4,info:8' \
        --color='border:8,list-border:8,preview-border:8,label:4:bold,gutter:-1')
[[ -z "$id" ]] && exit 0

content="$(decode "$id")"
# Copied files go back on the clipboard as files, not as text
if [[ "$content" == file://* ]]; then
    printf '%s\r\n' "$content" | setsid -f wl-copy --type text/uri-list >/dev/null 2>&1
else
    decode "$id" | setsid -f wl-copy >/dev/null 2>&1
fi

# Paste into the window that had focus, once this one has closed.
# Terminals paste with Ctrl+Shift+V, everything else with Ctrl+V.
setsid -f bash -c '
    for _ in {1..40}; do
        class="$(hyprctl activewindow -j | jq -r .class)"
        [[ "$class" != clipboard-history ]] && break
        sleep 0.05
    done
    sleep 0.05
    case "$class" in
        kitty|foot|Alacritty|*[Tt]erm*) wtype -M ctrl -M shift -k v ;;
        *) wtype -M ctrl -k v ;;
    esac
' </dev/null >/dev/null 2>&1
