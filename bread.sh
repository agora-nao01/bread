#!/data/data/com.termux/files/usr/bin/bash

# bread
# ASCII object animation engine
# Usage:
#   bread rotate
#   bread -l doritos rotate

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREADS_JSON="$SCRIPT_DIR/breads.json"

die() {
    printf 'bread: %s\n' "$1" >&2
    exit 1
}

usage() {
    cat <<EOF
Usage:
  bread rotate
  bread -l <skin> rotate

Options:
  -l <skin>    Load a skin from breads.json
  -h           Show this help
EOF
    exit 0
}

command -v python >/dev/null 2>&1 || die "Python is required"

[ -f "$BREADS_JSON" ] || die "breads.json not found"

SKIN="default"
ACTION=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        -l)
            [ "$#" -ge 2 ] || die "missing skin name"
            SKIN="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        rotate)
            ACTION="rotate"
            shift
            ;;
        *)
            die "unknown argument: $1"
            ;;
    esac
done

[ -n "$ACTION" ] || usage

# Resolve the skin path from breads.json
SKIN_FILE="$(
    python - "$BREADS_JSON" "$SKIN" <<'PY'
import json
import sys

json_file = sys.argv[1]
skin = sys.argv[2]

with open(json_file, "r", encoding="utf-8") as f:
    breads = json.load(f)

if skin not in breads:
    print("", end="")
    sys.exit(1)

print(breads[skin])
PY
)" || die "skin '$SKIN' not found"

[ -n "$SKIN_FILE" ] || die "skin '$SKIN' not found"

SKIN_PATH="$SCRIPT_DIR/$SKIN_FILE"

[ -f "$SKIN_PATH" ] || die "skin file not found: $SKIN_PATH"

# Extract frames from the Markdown animation file.
#
# Format:
# ---
# frame: 1
# ---
# ASCII ART
# ---
# frame: 2
# ---
# ASCII ART

mapfile -t FRAMES < <(
    python - "$SKIN_PATH" <<'PY'
import re
import sys

path = sys.argv[1]

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

blocks = re.split(r'(?m)^---\s*$', content)

frames = []

for i in range(len(blocks) - 1):
    metadata = blocks[i].strip()
    body = blocks[i + 1]

    match = re.search(r'(?m)^frame:\s*(\d+)\s*$', metadata)

    if not match:
        continue

    frame_number = int(match.group(1))

    # The next delimiter separates this frame from the next one.
    next_parts = re.split(r'(?m)^---\s*$', body, maxsplit=1)
    artwork = next_parts[0].strip("\n")

    frames.append((frame_number, artwork))

frames.sort(key=lambda x: x[0])

for _, artwork in frames:
    print(artwork.replace("\n", "\x1e"))
    print("\x1f")
PY
)

[ "${#FRAMES[@]}" -gt 0 ] || die "no frames found in $SKIN_PATH"

cleanup() {
    printf '\033[?25h'
    printf '\033[0m'
    clear
    exit 0
}

trap cleanup INT TERM

printf '\033[?25l'
clear

while true; do
    for frame in "${FRAMES[@]}"; do
        printf '\033[H'

        # Restore newlines encoded by the parser.
        printf '%s' "$frame" |
            tr '\036' '\n' |
            tr '\037' '\n'

        sleep 0.10
    done
done
