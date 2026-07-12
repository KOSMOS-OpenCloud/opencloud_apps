#!/bin/bash
set -euo pipefail

# Deploy web extensions from Codeberg Generic Packages to a remote host.
#
# Usage:
#   ./deploy_zip.sh --app all                          # all apps, latest
#   ./deploy_zip.sh --app draw-io --tag 20260705-1200  # specific app+version
#   ./deploy_zip.sh --app all --host cloud.brandis.eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/DIST"

REGISTRY="codeberg.org"
OWNER="kosmos-eu"
TAG="latest"
SELECTED="all"
TARGET_BASE="web-extensions"
RESTART_CMD="cd ${DATAPATH} && podman compose restart opencloud 2>&1 | tail -3"

while [[ $# -gt 0 ]]; do
  case $1 in
    --app)      SELECTED="$2"; shift 2 ;;
    --tag)      TAG="$2"; shift 2 ;;
    --host)     HOST="$2"; shift 2 ;;
    --no-restart) RESTART_CMD=""; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

for app in $APPS; do
    if [ "$SELECTED" != "all" ] && [ "$SELECTED" != "$app" ]; then
        continue
    fi

    PACKAGE="${app}-web"
    RESOLVE_TAG="$TAG"

    # Resolve "latest" tag
    if [ "$RESOLVE_TAG" = "latest" ]; then
        RESOLVE_TAG=$(curl -sf "https://${REGISTRY}/api/v1/packages/${OWNER}?type=generic&q=${PACKAGE}" \
          | python3 -c "
import sys, json
pkgs = [p for p in json.load(sys.stdin) if p['name'] == '${PACKAGE}' and p['version'] != 'latest']
if not pkgs:
    print('NOT_FOUND', file=sys.stderr); sys.exit(1)
print(pkgs[0]['version'])
" 2>/dev/null) || { echo "SKIP: ${PACKAGE} not found on registry"; continue; }
    fi

    ZIP_URL="https://${REGISTRY}/api/packages/${OWNER}/generic/${PACKAGE}/${RESOLVE_TAG}/${PACKAGE}.zip"
    REMOTE_DIR="${DATAPATH}/${TARGET_BASE}/${app}"

    echo "=== Deploy ${PACKAGE}:${RESOLVE_TAG} -> ${HOST} ==="
    ssh -o ConnectTimeout=10 "root@${HOST}" bash -s <<REMOTE
set -euo pipefail
TMPDIR=\$(mktemp -d); trap 'rm -rf \$TMPDIR' EXIT
curl -sfL -o "\$TMPDIR/pkg.zip" "${ZIP_URL}"
mkdir -p "${REMOTE_DIR}"; rm -rf "${REMOTE_DIR:?}"/*
cd "${REMOTE_DIR}" && python3 -c "
import zipfile, sys
with zipfile.ZipFile('\$TMPDIR/pkg.zip') as z:
    z.extractall('.')
    print(f'  {len(z.namelist())} files extracted')
"
REMOTE
done

if [ -n "$RESTART_CMD" ]; then
    echo "[restart] opencloud"
    ssh -o ConnectTimeout=10 "root@${HOST}" "$RESTART_CMD"
fi

echo ""
# Wait for cloud to come back
echo -n "Waiting for https://${HOST} ..."
for i in $(seq 1 30); do
    sleep 2
    STATUS=$(curl -sf -o /dev/null -w "%{http_code}" "https://${HOST}" 2>/dev/null || echo "000")
    if [ "$STATUS" = "200" ]; then
        echo " OK"
        break
    fi
    echo -n "."
done
[ "$STATUS" != "200" ] && echo " WARNING: not 200 after 60s"
echo "=== Deploy complete ==="
