#!/bin/bash
set -euo pipefail

# Build and push web extensions as ZIPs to Codeberg Generic Packages.
#
# Usage:
#   ./push_zip.sh              # build + push all apps
#   ./push_zip.sh draw-io      # single app
#   TAG=1.0.0 ./push_zip.sh   # explicit tag
#
# Requires: CODEBERG_TOKEN env var (or in ~/.codeberg-token)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/DIST"

SELECTED="${1:-all}"
REGISTRY="codeberg.org"
OWNER="kosmos-eu"
TAG="${TAG:-$(date +%Y%m%d-%H%M)}"
BUILD_DIR="$SCRIPT_DIR/dist"

# Token
if [ -z "${CODEBERG_TOKEN:-}" ] && [ -f ~/.codeberg-token ]; then
    CODEBERG_TOKEN="$(cat ~/.codeberg-token)"
fi
: "${CODEBERG_TOKEN:?Set CODEBERG_TOKEN or create ~/.codeberg-token}"

# Build first
"$SCRIPT_DIR/build.sh" "$SELECTED"

# Push each app
for app in $APPS; do
    if [ "$SELECTED" != "all" ] && [ "$SELECTED" != "$app" ]; then
        continue
    fi

    APP_DIR="$BUILD_DIR/$app"
    if [ ! -d "$APP_DIR" ]; then
        echo "SKIP: $APP_DIR not found"
        continue
    fi

    PACKAGE="${app}-web"
    TMPZIP="$(mktemp -t "${PACKAGE}-XXXXXX.zip")"
    trap "rm -f '$TMPZIP'" EXIT

    (cd "$APP_DIR" && zip -qr "$TMPZIP" .)
    ZIP_SIZE="$(du -h "$TMPZIP" | cut -f1)"

    UPLOAD_URL="https://${REGISTRY}/api/packages/${OWNER}/generic/${PACKAGE}/${TAG}/${PACKAGE}.zip"
    echo "[push] ${PACKAGE}:${TAG} ($ZIP_SIZE)"
    curl -sf -X PUT "$UPLOAD_URL" \
        -H "Authorization: token ${CODEBERG_TOKEN}" \
        --upload-file "$TMPZIP" && echo "  OK" || echo "  FAILED"

    rm -f "$TMPZIP"
done

echo ""
echo "=== Pushed (tag: $TAG) ==="
echo ""
echo "Deploy with:"
echo "  ./deploy_zip.sh --app all --tag $TAG"
