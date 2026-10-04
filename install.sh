#!/data/data/com.termux/files/usr/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$PREFIX/share/bread"
BIN_DIR="$PREFIX/bin"

echo "Installing bread..."

mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/skin"

cp "$PROJECT_DIR/breads.json" "$INSTALL_DIR/"
cp "$PROJECT_DIR/default.md" "$INSTALL_DIR/"

if [ -d "$PROJECT_DIR/skin" ]; then
    cp -r "$PROJECT_DIR/skin/." "$INSTALL_DIR/skin/"
fi

cp "$PROJECT_DIR/bread" "$BIN_DIR/bread"
chmod +x "$BIN_DIR/bread"

echo
echo "bread installed successfully!"
echo
echo "Try:"
echo "  bread rotate"
