# Backend, Keycloak and Docker setup

`gf-app` runs against the Gorape repository's existing Docker Compose
environment. Nothing in the backend checkout is modified: this repository only
adds overrides under `docker/` and orchestrates them with `scripts/`.

## Layout assumption

```
Gorapeflutter/
  gorape/     backend checkout, owns docker/*.yaml and etc/server.yaml.docker
  gf-app/     this Flutter client
```

If the repositories are not siblings, point the scripts at the backend:

```bash
export GORAPE_BACKEND_DIR=/absolute/path/to/gorape
```

## How Compose is assembled

`scripts/lib.sh` starts from the same files as the backend `Makefile`:

```
docker/network.yaml
docker/postgres.yaml
docker/pgadmin.yaml
docker/redis.yaml
docker/keycloak.yaml
docker/server.yaml
docker/swagger.yaml
docker/godoc.yaml
docker/localstack.yaml
```

Only then does it append gf-app overrides:

- `docker/server.image.yaml` — use a published Docker Hub image instead of the
  local build.
- `docker/server.android-attestation.yaml` — replace the mounted server config
  with a generated copy that has Google's Android Key Attestation roots.

`docker/server.android-attestation.yaml` uses the Compose `!override` tag to
replace the server `volumes` list, so the original `docker/server.yaml` remains
untouched. Compose v2.24+ is required.

## Android trust anchors

Gorape's Android verifier reads
`Application.Server.Attestation.android_trust_anchors`, a list of files inside
the server container. With the default backend config the list is empty, so
`GET /v1/projects/{projectId}/attestation/capabilities` returns
`android: "unconfigured"` and registration fails with HTTP 422.

Generate a config that points at Google's published roots:

```bash
./scripts/generate-android-trust-config.sh
```

This downloads `https://android.googleapis.com/attestation/root`, validates the
certificates with `openssl` when available, and writes:

```
config/generated/android-attestation-roots.pem
config/generated/server.yaml
```

`server.yaml` is a byte-for-byte copy of `gorape/etc/server.yaml.docker` except
for the attestation line, which becomes:

```yaml
attestation: {android_trust_anchors: ["/app/etc/android/android-attestation-roots.pem"]}
```

The Compose override mounts the generated files at:

```
config/generated/server.yaml                      -> /app/etc/server.yaml
config/generated/android-attestation-roots.pem    -> /app/etc/android/android-attestation-roots.pem
```

To use a custom root bundle (for example a private enterprise CA), pass
`--source FILE_OR_URL`. Regenerate after Google rotates the roots, then restart
the server with `./scripts/gorape-up.sh --android-attestation`.

### Verify the verifier is active

```bash
curl -s http://localhost:8000/health

TOKEN=$(cat ../gorape/etc/.gorape/client/admin/access_token)
PROJECT_ID=$(curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/v1/projects | python3 -c \
  'import json,sys; print(json.load(sys.stdin)[0]["id"])')

curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/v1/projects/$PROJECT_ID/attestation/capabilities"
```

Expected:

```json
{"verifiers":{"android":"implemented","ios":"unsupported","macos":"unsupported","windows":"unsupported"}}
```

If you do not have a token yet, build and use the backend CLI:

```bash
cd ../gorape
make build
.bin/gorape-client -c etc/app.yaml login
cat etc/.gorape/client/admin/access_token
```

The CLI uses the same `gorape-client` and redirect
`http://127.0.0.1:8400/callback`.

## Keycloak

Realm and client:

| Item | Value |
| --- | --- |
| Issuer | `http://localhost:8080/realms/gorape` |
| Client | `gorape-client` (public) |
| Flow | Authorization Code + PKCE S256 |
| Scopes | `openid profile` |
| Audience | `gorape-api` (dedicated audience mapper) |
| CLI redirect | `http://127.0.0.1:8400/callback` (preserved) |
| Flutter redirect | `com.gorapeflutter.gfapp:/oauth2redirect` |

Add the Flutter redirect while keeping the CLI redirect:

```bash
./scripts/keycloak-allow-redirect.sh
```

The script talks to the Keycloak Admin API (`admin` / `admin` by default), merges
the URI list, ensures `pkce.code.challenge.method=S256`, keeps
`post.logout.redirect.uris=+`, and is idempotent. Use `--show` to inspect the
current client.

Manual alternative: Keycloak Admin Console → realm `gorape` → Clients →
`gorape-client` → Valid redirect URIs → add
`com.gorapeflutter.gfapp:/oauth2redirect` and save. Do not remove the CLI URI.

> The script changes the running Keycloak database only. The realm import file
> in the backend (`etc/keycloak/gorape-realm.json`) is not edited. If you remove
> the Keycloak volume (`./scripts/gorape-down.sh --volumes`), the realm is
> re-imported without the Flutter URI and you must run the script again. To make
> it permanent, intentionally add the URI to the backend realm JSON.

The realm also supports native-app custom schemes; the auth endpoint accepts the
redirect URI once it is allow-listed. PKCE is required, so no client secret is
stored in the app.

## Starting and stopping

```bash
./scripts/gorape-up.sh                        # local build, core services
./scripts/gorape-up.sh --android-attestation  # + generated trust anchors
./scripts/gorape-up.sh --all                  # + pgadmin/swagger/godoc/localstack
./scripts/gorape-up.sh --server-only          # API only, dependencies already up
./scripts/gorape-up.sh --hub TAG --pull       # published image

./scripts/gorape-down.sh                      # stop containers, keep volumes
./scripts/gorape-down.sh --server             # remove only the API container
./scripts/gorape-down.sh --volumes            # destructive: delete data
```

Ports used by the development environment:

| Service | URL |
| --- | --- |
| Gorape API | http://localhost:8000 |
| Health | http://localhost:8000/health |
| Keycloak | http://localhost:8080 |
| Keycloak admin | http://localhost:8080/admin |
| pgAdmin | http://localhost:3001 |
| Swagger UI (optional) | http://localhost:3002 |

Development credentials come from the backend repository:

- Keycloak admin: `admin` / `admin`
- Seeded realm users: see `gorape/etc/keycloak/gorape-realm.json`
  (`gorape-admin` uses the temporary password `ChangeMe123!`)

Treat all of these as local-only.

## Published image override

`docker/server.image.yaml`:

```yaml
services:
  server:
    image: ${GORAPE_SERVER_IMAGE:-gorapeflutter/gorape:latest}
    build: !reset null
```

`!reset` removes the `build` section inherited from the backend compose file so
Compose uses the image. Pin a tag (`sha-…`) or digest for reproducible runs; the
`latest` tag changes over time.

When `--android-attestation` is also used, the generated `server.yaml` is copied
from the local backend checkout. Keep the checkout and the pinned image on the
same release so the mounted config matches the image's expected schema.

## Troubleshooting

- **`error: duplicate mount point /app/etc/server.yaml`** — Compose is older
  than v2.24 and does not support `!override`. Upgrade Docker Compose, or remove
  the generated override and run against the backend default config.
- **`Missing …/config/generated/server.yaml`** — run
  `./scripts/generate-android-trust-config.sh` first. The start script requires
  both generated files when `--android-attestation` is passed.
- **Capabilities stay `unconfigured`** — the server was started without the
  attestation override. Restart with
  `./scripts/gorape-up.sh --android-attestation --no-build`, then check the
  container mounts:
  `docker inspect gorape --format '{{json .Mounts}}'`.
- **Keycloak returns `invalid_redirect_uri`** — run
  `./scripts/keycloak-allow-redirect.sh` and confirm the URI appears in
  `--show` output.
- **Backend cannot start after deleting volumes** — Keycloak imports the realm
  on first boot; give it up to a minute, then rerun the health wait or check
  `docker logs gorape-keycloak`.
