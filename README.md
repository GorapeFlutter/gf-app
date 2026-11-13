# gf-app — Gorape Flutter client

Flutter client for the [Gorape](../gorape) device trust / attestation backend.
The app signs in with Keycloak (Authorization Code + PKCE), calls the Gorape
OpenAPI 3.1 API with the **access token**, and registers Android devices using a
hardware-backed Keystore key whose attestation challenge is bound to the
server-issued registration challenge.

The backend repository remains the single source of truth. This project does not
fork or edit the Gorape Docker environment; it adds Compose overrides and
development scripts that layer on top of it.

## What is implemented

- Keycloak login for Android, iOS and macOS via `flutter_appauth`
  (public client, PKCE S256, `openid profile`, audience `gorape-api`).
- Access-token-only Gorape API client. The ID token is never sent to Gorape.
  An expired access token triggers one refresh-and-retry instead of dropping the
  session.
- Project, device, registration, proof and attestation endpoints from
  `gorape/docs/swagger/swagger.yaml`.
- Android registration:
  - EC P-256 key generated inside Android Keystore (StrongBox when available).
  - Raw registration challenge passed to
    `KeyGenParameterSpec.setAttestationChallenge`.
  - Certificate chain submitted leaf-first as PEM.
  - Possession proof signs the raw challenge bytes with
    `SHA256withECDSA`; the ASN.1 signature is sent as unpadded Base64url.
- Explicit OS support matrix in the UI and live backend verifier capabilities.
- iOS/macOS/Windows/Linux/Web interfaces are modelled without pretending the
  backend supports their attestation.
- Local-only policy preferences, clearly labelled as not enforced by Gorape
  (the backend has no policy API).
- Automated tests for API contracts, settings, local policy, registration and
  proof orchestration.

## Requirements

- Flutter 3.38+/Dart 3.10+ (developed with Flutter 3.38.2 / Dart 3.10).
- Docker Desktop with Docker Compose **v2.24 or newer** (the overrides use
  `!reset` / `!override`).
- The Gorape backend checkout, by default as a sibling directory:
  `../gorape`.
- Android SDK plus a connected emulator or physical device for Android work.
- Xcode for iOS/macOS builds (not installed/validated in this environment).

## Quick start (local backend build)

```bash
cd gf-app

# 1. Download Google's Android Key Attestation roots and generate a server
#    config that points at them. Files go to git-ignored config/generated/.
./scripts/generate-android-trust-config.sh

# 2. Build/start postgres, redis, keycloak and the Gorape server from ../gorape.
./scripts/gorape-up.sh --android-attestation

# 3. Allow the Flutter redirect URI on the existing Keycloak client. Existing
#    CLI redirect http://127.0.0.1:8400/callback is preserved.
./scripts/keycloak-allow-redirect.sh

# 4. Run on a connected Android device. adb reverse maps localhost:8000 and
#    localhost:8080 back to the host so the OIDC issuer stays consistent.
./scripts/run-android.sh
```

Check that the backend now exposes an implemented Android verifier:

```bash
curl -s http://localhost:8000/health
# {"service":"gorape","status":"ok"}

TOKEN=$(cat ../gorape/etc/.gorape/client/admin/access_token)
curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/v1/projects/805c5265-7315-420b-8aa7-3aea715ed88a/attestation/capabilities
# {"verifiers":{"android":"implemented","ios":"unsupported", ...}}
```

The project ID above is the seeded development project. If your database is
different, use any ID returned by `GET /v1/projects`.

## Using the published Docker Hub image

The image is an override; the backend compose file is untouched.

```bash
# Floating latest (fine for experiments)
./scripts/gorape-up.sh --hub --android-attestation

# Recommended: pin a published tag or digest
GORAPE_SERVER_IMAGE=gorapeflutter/gorape:sha-7d9703b \
  ./scripts/gorape-up.sh --hub --pull --android-attestation
```

Available tags are visible on Docker Hub (`latest`, `main`, `sha-…`). The
override sets `image` and removes the local `build` section with
`build: !reset null`.

## Configuration

Runtime defaults:

| Setting | Default | Notes |
| --- | --- | --- |
| API base URL | `http://10.0.2.2:8000` on Android, `http://localhost:8000` elsewhere | Android emulator host alias |
| OIDC issuer | `http://localhost:8080/realms/gorape` | Must exactly match Keycloak's `iss` |
| Client ID | `gorape-client` | Public client, PKCE only |
| Redirect URI | `com.gorapeflutter.gfapp:/oauth2redirect` | Registered on the Keycloak client |
| Scopes | `openid profile` | Audience `gorape-api` comes from a mapper |

Override at build/run time with `--dart-define`:

```bash
flutter run \
  --dart-define=GORAPE_API_BASE_URL=http://192.168.1.10:8000 \
  --dart-define=GORAPE_OIDC_ISSUER=http://gorape.local:8080/realms/gorape \
  --dart-define=GORAPE_OIDC_CLIENT_ID=gorape-client \
  --dart-define=GORAPE_OIDC_REDIRECT_URI=com.gorapeflutter.gfapp:/oauth2redirect
```

Values can also be edited in the app under **Settings**. They are stored in the
OS secure storage, not in the Gorape backend.

> The OIDC issuer must remain identical to the issuer that Keycloak puts in the
> token. Replacing only the host (for example using `10.0.2.2` for the issuer)
> makes token validation fail. Use `adb reverse tcp:8080 tcp:8080` or a proper
> hostname with matching Keycloak hostname configuration instead.

## API surface

Only endpoints present in the backend OpenAPI contract are used:

| Method | Path |
| --- | --- |
| GET | `/health` |
| GET | `/v1/projects` |
| GET | `/v1/projects/{projectId}` |
| GET | `/v1/projects/{projectId}/devices` |
| GET | `/v1/projects/{projectId}/devices/{deviceId}` |
| DELETE | `/v1/projects/{projectId}/devices/{deviceId}` |
| POST | `/v1/projects/{projectId}/devices/registration/challenge` |
| POST | `/v1/projects/{projectId}/devices/registration/verify` |
| POST | `/v1/projects/{projectId}/devices/{deviceId}/challenge` |
| POST | `/v1/projects/{projectId}/devices/{deviceId}/verify` |
| GET | `/v1/projects/{projectId}/attestation/capabilities` |
| GET | `/v1/projects/{projectId}/devices/{deviceId}/attestation` |

There is deliberately no policy, passkey or group-management API in the client:
the current backend contract does not define a policy endpoint.

## OS support

App-side capabilities (the backend column is fetched live):

| Platform | Keycloak login | OS-protected key | Attestation flow | Gorape verifier |
| --- | --- | --- | --- | --- |
| Android | Yes | Yes (Keystore, StrongBox preferred) | Yes | `implemented` when trust anchors are configured |
| iOS | Yes | Not implemented | No | `unsupported` |
| macOS | Yes | Not implemented | No | `unsupported` |
| Windows | No (`flutter_appauth` has no Windows implementation) | No | No | `unsupported` |
| Linux | No | No | No | Not a Gorape platform |
| Web | No | No | No | Not a Gorape platform |

iOS/macOS UI and URL schemes are present, but registration is intentionally
disabled because the backend returns `unsupported`. Adding App Attest/Secure
Enclave support requires a backend verifier first.

Passkeys and MFA stay in Keycloak. Gorape only stores the device public key and
verifies possession. The app never stores passkey secrets or passwords.

## Project layout

```
lib/
  api/              Gorape HTTP client and OpenAPI models
  auth/             OIDC abstraction, AppAuth adapter, token/session models
  core/             Config, secure storage, errors, JWT/Base64url utilities
  device_keys/      Android Keystore bridge, registration/proof orchestration
  platform/         Static OS support matrix
  policy/           Local-only policy model (not sent to Gorape)
  state/            Riverpod controllers/providers
  ui/               Login, projects, devices, registration, support, settings
android/            MainActivity.kt Keystore/attestation MethodChannel
docker/             gf-app Compose overrides (backend files are not edited)
scripts/            Backend, Keycloak, trust-anchor and Android dev helpers
test/               Unit/widget tests
```

## Development checks

```bash
./scripts/check.sh          # format check + dart analyze + flutter test
./scripts/check.sh --apk    # additionally build the debug APK
```

`dart analyze` is used instead of `flutter analyze`: in this SDK build
`flutter analyze` crashes because the `analysis_server.dart.snapshot` file is
missing while the AOT snapshot exists.

## Security notes

- Local development uses HTTP. Release builds must use HTTPS for the API and
  Keycloak, and a registered HTTPS or platform-native redirect URI.
- Only the access token is sent to Gorape. The ID token is kept for sign-out
  hints and never used as an API bearer token.
- Android private keys never leave the Keystore. Only the alias is persisted in
  secure storage; the public key and certificate chain are sent to Gorape.
- `config/generated/` is git-ignored because it contains machine-specific
  absolute paths and downloaded trust anchors.
- The bundled Keycloak admin credentials (`admin` / `admin`) and seeded user
  passwords are development-only. Never reuse them outside local development.

## Known limitations

- Real attestation validation needs a device whose Keystore returns a chain
  rooted in Google's Key Attestation roots. Many emulators use software or test
  roots and will fail Gorape's verifier.
- iOS/macOS builds could not be validated here because Xcode is incomplete.
- Windows/Linux/Web have no OIDC login and no attestation support.
- The backend has no policy API; the policy screen is explicitly local-only.
- Swagger UI/godoc are optional containers (`make docs` in the backend).

## Further documentation

- [`docs/SETUP.md`](docs/SETUP.md) — Docker/Keycloak/trust-anchor details and
  verification commands.
- [`docs/ANDROID.md`](docs/ANDROID.md) — Android registration flow, emulator
  networking and attestation troubleshooting.
