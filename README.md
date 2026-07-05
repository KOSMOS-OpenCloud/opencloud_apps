# opencloud_apps

OpenCloud Web Extensions gebaut gegen die aktuelle OpenCloud Web-Version.

Übernimmt die upstream Extensions aus [web-extensions](https://github.com/opencloud-eu/web-extensions)
und baut sie als Module Federation Remotes für unsere OpenCloud-Deployments.

## Enthaltene Apps

| App | Upstream Package | Codeberg Package |
|-----|-----------------|-----------------|
| draw-io | web-app-draw-io | `draw-io-web` |
| external-sites | web-app-external-sites | `external-sites-web` |
| json-viewer | web-app-json-viewer | `json-viewer-web` |

## Workflow

```bash
# Bauen und auf Codeberg pushen
./build.sh                    # baut alle Apps
./push_zip.sh                 # pusht ZIPs nach codeberg.org/kosmos-eu/

# Auf Server deployen
./deploy_zip.sh --app draw-io --host cloud.os.brandis.parthe.cloud
./deploy_zip.sh --app all --host cloud.brandis.eu
```

## Voraussetzungen

- pnpm
- Node.js 20+
- CODEBERG_TOKEN (env var oder ~/.codeberg-token)
