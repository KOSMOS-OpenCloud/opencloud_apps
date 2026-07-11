#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/DIST"

WEB_EXT_DIR="$SCRIPT_DIR/web-extensions"
BUILD_DIR="${DIST_DIR:-$SCRIPT_DIR/dist}"

# Clone web-extensions if not present
if [ ! -d "$WEB_EXT_DIR/packages" ]; then
    echo "[clone] web-extensions"
    git clone --depth 1 https://github.com/opencloud-eu/web-extensions.git "$WEB_EXT_DIR"
fi

# Install deps
if [ ! -d "$WEB_EXT_DIR/node_modules" ]; then
    echo "[deps] Installing dependencies..."
    (cd "$WEB_EXT_DIR" && pnpm install)
fi

mkdir -p "$BUILD_DIR"

for app in $APPS; do
    PKG_DIR="$WEB_EXT_DIR/packages/web-app-${app}"
    if [ ! -d "$PKG_DIR" ]; then
        echo "SKIP: $PKG_DIR not found"
        continue
    fi

    echo "=== Build: $app ==="
    (cd "$PKG_DIR" && pnpm build)

    OUT_DIR="$PKG_DIR/dist"
    if [ ! -d "$OUT_DIR" ]; then
        echo "ERROR: $OUT_DIR not found after build"
        continue
    fi

    rm -rf "$BUILD_DIR/$app"
    cp -r "$OUT_DIR" "$BUILD_DIR/$app"
    echo "  -> $BUILD_DIR/$app/"
done

echo "=== Build complete ==="
