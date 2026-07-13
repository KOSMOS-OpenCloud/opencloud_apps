#!/bin/bash
set -euo pipefail
export CI=true

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/DIST"

BUILD_DIR="${DIST_DIR:-$SCRIPT_DIR/dist}"
mkdir -p "$BUILD_DIR"

for app in $APPS; do
    APP_DIR="$SCRIPT_DIR/apps/$app"
    if [ ! -d "$APP_DIR" ]; then
        echo "SKIP: $APP_DIR not found"
        continue
    fi

    echo "=== Build: $app ==="
    (cd "$APP_DIR" && pnpm install && pnpm build)

    OUT_DIR="$APP_DIR/dist"
    if [ ! -d "$OUT_DIR" ]; then
        echo "ERROR: $OUT_DIR not found after build"
        continue
    fi

    rm -rf "$BUILD_DIR/$app"
    cp -r "$OUT_DIR" "$BUILD_DIR/$app"
    echo "  -> $BUILD_DIR/$app/"
done

echo "=== Build complete ==="
