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

## Legacy Android Keystore trust anchors

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

`server.yaml` is a copy of `gorape/etc/server.yaml.docker` with only the legacy
Android trust-anchor setting changed:

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

## Gorape RP passkeys and attestation

The device-registration screen uses a separate WebAuthn ceremony for Gorape.
Keycloak credentials belong to Keycloak's RP ID and cannot be reused. Set one
stable Gorape RP ID and exact app/browser origins in the backend config:

```yaml
Application:
  Server:
    webauthn:
      rp_id: gorape.example.com
      rp_display_name: Gorape
      rp_origins:
        - https://app.gorape.example.com
        - android:apk-key-hash:BASE64URL_CERTIFICATE_HASH
      portal_origin: https://app.gorape.example.com
      browser_api_origin: https://api.gorape.example.com
      attestation_conveyance: direct
      user_verification: required
    web_origins: [https://app.gorape.example.com]
    attestation:
      webauthn:
        allowed_formats: [android-key, tpm, apple]
        allow_none: false
        allow_self_attestation: false
        trust_anchors:
          android-key: [/app/etc/android/android-attestation-roots.pem]
          tpm: [/app/etc/tpm/tpm-attestation-roots.pem]
          apple: [/app/etc/apple/apple-webauthn-roots.pem]
```

The local Docker config uses RP ID `gorapeflutter.github.io`, distinct from
Keycloak's `localhost`, and allows the current Android debug
`android:apk-key-hash` origin. Attestation format `none` is enabled for local
testing. The organization Pages repository
`../gorapeflutter.github.io` publishes
`https://gorapeflutter.github.io/.well-known/assetlinks.json`; its statement
associates package `com.gorapeflutter.gf_app` with the current debug signing
certificate with both `delegate_permission/common.get_login_creds` and
`delegate_permission/common.handle_all_urls`. The API
endpoint remains `https://localhost:8443`; it is separate
from the RP domain and its local CA is not used for Digital Asset Links.
Backend implementation references: [GF-10010](https://github.com/Gorapeflutter/gorape/blob/main/pkg/server/repository/webauthn.go#L87)–[GF-10011](https://github.com/Gorapeflutter/gorape/blob/main/pkg/server/repository/webauthn.go#L577) validate the RP
identity, while [GF-10016](https://github.com/Gorapeflutter/gorape/blob/main/pkg/server/usecase/passkey_device.go#L91)–[GF-10017](https://github.com/Gorapeflutter/gorape/blob/main/pkg/server/usecase/passkey_device.go#L151) issue and verify the registration.
The [complete backend source ID index](https://github.com/Gorapeflutter/gorape/blob/main/docs/book/src/source-index.md)
is maintained with the Gorape documentation.

For another debug signing key, add its SHA-256 certificate fingerprint to the
Pages `assetlinks.json` and its `android:apk-key-hash:` value to
`../gorape/etc/server.yaml.docker`'s `webauthn.rp_origins`, then redeploy Pages
and regenerate the server config.

For local API HTTPS (separate from the Android RP-domain requirement), run:

```bash
./scripts/generate-local-tls.sh [--host <local-dns-name>]
./scripts/gorape-up.sh --https --android-attestation
curl --cacert config/generated/tls/ca.crt https://localhost:8443/health
```

This creates a local CA and certificate under the Git-ignored
`config/generated/tls/`; the private keys are mode `0600`. The CA is for local
API transport only and must not be used as a production trust anchor. Android's
native passkey RP association is provided separately by the public Pages site.
`./scripts/run-android.sh` uses the generated CA for the debug Dart client and
sets the API URL to `https://localhost:8443`.

The default empty format allowlist, `allow_none: false`, and
`allow_self_attestation: false` reject registrations. Mount each configured
trust bundle into the backend container. `android-key` reuses
`android_trust_anchors` when its WebAuthn-specific list is empty.

The client and RP domain must also be associated on each native platform:

- Android: publish Digital Asset Links with both
  `delegate_permission/common.get_login_creds` and
  `delegate_permission/common.handle_all_urls` for the app package and all
  signing certificate fingerprints at
  `https://<rp-id>/.well-known/assetlinks.json`.
- iOS/macOS: publish AASA `webcredentials` entries and add
  `webcredentials:<rp-id>` to the app's Associated Domains entitlement.
- Web: serve from a secure origin; the RP ID must be the page host or a parent
  domain. Register the Web origin and Keycloak CORS origin.
- Windows: uses the Windows WebAuthn API; TPM attestation is provider-dependent.
- Linux: use Chrome/Firefox; the gf-app web target supplies a browser ceremony
  page while Gorape remains an API-only backend.

`direct` is a conveyance preference, not a guarantee. The server verifies the
actual `fmt` and certificate chain. `rp_origins` are exact values: HTTPS origins
must be under the RP ID, HTTP is only allowed for localhost development, and
native Android origins must be explicitly listed. Do not use wildcards.
`portal_origin` must be in both `rp_origins` and `web_origins`; `browser_api_origin`
must match the Gorape API URL configured in gf-app. The Linux ceremony page is
hosted by gf-app; Gorape serves only APIs. Windows/Linux use the
`http://127.0.0.1:8401/oauth2redirect` system-browser callback. For local Web
development, run Flutter on port 5000 and register
`http://localhost:5000/auth.html` plus `http://localhost:5000` as redirect/origin.
Linux builds need GTK/WebKitGTK development packages from
`desktop_webview_window`, while OIDC/passkey flows open the installed system
browser.

### Native Device Trust keys

gf-app has OS-local Device key providers: Android Keystore, Apple Secure
Enclave, Windows Platform Crypto Provider, and Linux TPM2. Linux runtime key
operations require `tpm2-tools` and access to `/dev/tpmrm0`; the provider pins
the device TCTI and never falls back to a software key. Apple/Windows/Linux
legacy raw-key providers currently do not send a server-verifiable same-key
attestation, so device registration uses the WebAuthn passkey ceremony
(`PasskeyDeviceUsecase`) as the primary path.

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
| Android/iOS/macOS redirect | `com.gorapeflutter.gfapp:/oauth2redirect` |
| Windows/Linux redirect | `http://127.0.0.1:8401/oauth2redirect` |
| Web redirect | Same-origin `/auth.html` (local development: `http://localhost:5000/auth.html`) |

On a fresh local database, redirect URIs, passwordless WebAuthn, the passkey-only
login flow, the `gorape-passkey-amr` mapper, and the registration required action
are imported from `../gorape/etc/keycloak/gorape-realm.json`. The **Register a
Keycloak passkey** button uses the WebAuthn Passwordless AIA. **Sign in with a
passkey** requests the dedicated flow without username/password forms. Its
successful WebAuthn execution emits `amr: ["passkey"]`; Gorape only permits
device registration and proof when the signed access token contains that claim.

The local PostgreSQL container loads `../gorape/scripts/data/postgres/004-gorape-demo-seed.sql`
after the schema migrations. It creates the `demo` project and permission test
fixtures, so no `gorape-admin provision apply` step is needed for the local
stack. These files are applied only when a fresh database is initialized.
Recreating the local tmpfs Postgres container also resets Keycloak users and
registered passkeys.

For an already-existing realm, add Flutter redirect URIs/Web Origins through
Keycloak Admin Console → realm `gorape` → Clients → `gorape-client`, preserving
the CLI callback. Local Web runs at `http://localhost:5000/auth.html`.

If you remove the Keycloak/Postgres data, the realm and demo fixture are
re-imported from these files. Test passwords are documented in
`../gorape/etc/README.md`; device passkeys must be registered again.
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
 - **Keycloak returns `invalid_redirect_uri`** — on a fresh local database,
   confirm the imported client configuration in
   `../gorape/etc/keycloak/gorape-realm.json`; for an existing realm, add the
   redirect URI through Keycloak Admin Console without removing the CLI URI.
- **Backend cannot start after deleting volumes** — Keycloak imports the realm
  on first boot; give it up to a minute, then rerun the health wait or check
  `docker logs gorape-keycloak`.
