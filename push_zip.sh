#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SCRIPT_DIR/DIST" ] && . "$SCRIPT_DIR/DIST"

OWNER="${PUSH_ORG:-kosmos-eu}"
REPO="${REPO:-opencloud_apps}"
TAG="${TAG:-$(date +%Y%m%d-%H%M)}"
BUILD_DIR="${DIST_DIR:-$SCRIPT_DIR/dist}"
REGISTRY="${PUSH_REGISTRY:-codeberg}"

# Token: PACKAGES_TOKEN > PUSH_TOKEN > CODEBERG_TOKEN > ~/.codeberg-token
TOKEN="${PACKAGES_TOKEN:-${PUSH_TOKEN:-${CODEBERG_TOKEN:-}}}"
if [ -z "$TOKEN" ] && [ -f ~/.codeberg-token ]; then
    TOKEN="$(cat ~/.codeberg-token)"
fi
: "${TOKEN:?Set PACKAGES_TOKEN or PUSH_TOKEN in DIST}"

# Build (skip if already built by worker or dist/ exists)
if [ -z "${SKIP_BUILD:-}" ] && [ ! -d "$BUILD_DIR" ]; then
    bash "$SCRIPT_DIR/build_web.sh"
fi

echo "=== Push: registry=$REGISTRY owner=$OWNER repo=$REPO tag=$TAG ==="

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

    case "$REGISTRY" in
        github)
            echo "[push] ${PACKAGE}:${TAG} -> GitHub Release ${OWNER}/${REPO} (tag: pkg-${TAG}-${app})"
            RELEASE=$(curl -s -X POST "https://api.github.com/repos/${OWNER}/${REPO}/releases" \
                -H "Authorization: token ${TOKEN}" \
                -H "Content-Type: application/json" \
                -d "{\"tag_name\":\"pkg-${TAG}-${app}\",\"name\":\"${PACKAGE} ${TAG}\",\"draft\":false}")
            RELEASE_ID=$(echo "$RELEASE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null)
            if [ -z "$RELEASE_ID" ]; then
                echo "  ERROR creating release: $RELEASE"
                continue
            fi
            UPLOAD=$(curl -s -X POST "https://uploads.github.com/repos/${OWNER}/${REPO}/releases/${RELEASE_ID}/assets?name=${PACKAGE}.zip" \
                -H "Authorization: token ${TOKEN}" \
                -H "Content-Type: application/zip" \
                --data-binary "@${TMPZIP}")
            ASSET_STATE=$(echo "$UPLOAD" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('state',''))" 2>/dev/null)
            if [ "$ASSET_STATE" = "uploaded" ]; then
                echo "  OK"
            else
                echo "  ERROR uploading asset: $UPLOAD"
            fi
            ;;
        *)
            REGISTRY_HOST="${REGISTRY}.org"
            [[ "$REGISTRY" == *"."* ]] && REGISTRY_HOST="$REGISTRY"
            UPLOAD_URL="https://${REGISTRY_HOST}/api/packages/${OWNER}/generic/${PACKAGE}/${TAG}/${PACKAGE}.zip"
            echo "[push] ${PACKAGE}:${TAG}"
            curl -sf -X PUT "$UPLOAD_URL" \
                -H "Authorization: token ${TOKEN}" \
                --upload-file "$TMPZIP" && echo "  OK" || echo "  FAILED"
            # Also push as latest
            LATEST_URL="https://${REGISTRY_HOST}/api/packages/${OWNER}/generic/${PACKAGE}/latest/${PACKAGE}.zip"
            curl -sf -X DELETE "$LATEST_URL" -H "Authorization: token ${TOKEN}" -o /dev/null 2>/dev/null || true
            curl -sf -X PUT "$LATEST_URL" -H "Authorization: token ${TOKEN}" --upload-file "$TMPZIP" > /dev/null
            ;;
    esac

    rm -f "$TMPZIP"
done

echo "=== Pushed (tag: $TAG, registry: $REGISTRY) ==="
