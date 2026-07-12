#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/DIST"

REGISTRY="codeberg.org"
OWNER="${PUSH_ORG:-kosmos-eu}"
TAG="${TAG:-$(date +%Y%m%d-%H%M)}"
BUILD_DIR="$SCRIPT_DIR/dist"

# Token
if [ -z "${CODEBERG_TOKEN:-}" ] && [ -f ~/.codeberg-token ]; then
    CODEBERG_TOKEN="$(cat ~/.codeberg-token)"
fi
: "${CODEBERG_TOKEN:?Set CODEBERG_TOKEN or create ~/.codeberg-token}"

# Build
if [ -z "${SKIP_BUILD:-}" ]; then
    bash "$SCRIPT_DIR/build_web.sh"
fi

# Push each app
for app in $APPS; do
    APP_DIR="$BUILD_DIR/$app"
    if [ ! -d "$APP_DIR" ]; then
        echo "SKIP: $APP_DIR not found"
        continue
    fi

    PACKAGE="${app}-web"
    TMPZIP="/tmp/${PACKAGE}-${TAG}.zip"
    rm -f "$TMPZIP"

    (cd "$APP_DIR" && zip -qr "$TMPZIP" .)
    UPLOAD_URL="https://${REGISTRY}/api/packages/${OWNER}/generic/${PACKAGE}/${TAG}/${PACKAGE}.zip"
    echo "[push] ${PACKAGE}:${TAG}"
    curl -sf -X PUT "$UPLOAD_URL" \
        -H "Authorization: token ${CODEBERG_TOKEN}" \
        --upload-file "$TMPZIP" && echo "  OK" || echo "  FAILED"
    rm -f "$TMPZIP"
done

echo "=== Pushed (tag: $TAG) ==="
