#!/bin/bash
set -euo pipefail

# Build upstream web extensions from local web-extensions checkout.
#
# Usage:
#   ./build.sh              # build all apps
#   ./build.sh draw-io      # build single app

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/DIST"

SELECTED="${1:-all}"
BUILD_DIR="$SCRIPT_DIR/dist"

if [ ! -d "$WEB_EXTENSIONS_DIR/packages" ]; then
    echo "ERROR: web-extensions repo not found at $WEB_EXTENSIONS_DIR"
    echo "Set WEB_EXTENSIONS_DIR or clone web-extensions repo"
    exit 1
fi

# Install deps if needed
if [ ! -d "$WEB_EXTENSIONS_DIR/node_modules" ]; then
    echo "[deps] Installing web-extensions dependencies..."
    (cd "$WEB_EXTENSIONS_DIR" && pnpm install)
fi

mkdir -p "$BUILD_DIR"

for app in $APPS; do
    if [ "$SELECTED" != "all" ] && [ "$SELECTED" != "$app" ]; then
        continue
    fi

    PKG_DIR="$WEB_EXTENSIONS_DIR/packages/web-app-${app}"
    if [ ! -d "$PKG_DIR" ]; then
        echo "SKIP: $PKG_DIR not found"
        continue
    fi

    echo "=== Build: $app ==="
    (cd "$PKG_DIR" && pnpm build)

    # Copy build output
    OUT_DIR="$PKG_DIR/dist"
    if [ ! -d "$OUT_DIR" ]; then
        echo "ERROR: $OUT_DIR not found after build"
        continue
    fi

    rm -rf "$BUILD_DIR/$app"
    cp -r "$OUT_DIR" "$BUILD_DIR/$app"
    echo "  -> $BUILD_DIR/$app/ ($(find "$BUILD_DIR/$app" -type f | wc -l) files)"
    echo ""
done

echo "=== Build complete ==="
