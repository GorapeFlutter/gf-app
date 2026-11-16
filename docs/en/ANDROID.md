# Android registration and attestation

The primary device-registration path on Android is the Gorape RP WebAuthn
passkey ceremony. This chapter documents the separate legacy Android Key
Attestation flow, which the backend verifier still implements for compatibility.

Legacy Android Key Attestation is an app-generated device key, not WebAuthn
passkey attestation. See the [architecture chapter](ARCHITECTURE.md) for the
TPM and passkey-attestation comparison. Passkey assurance (`hardware_attested`,
`device_bound_unattested`, `standard_passkey`, `rejected`) is derived by Gorape
from verified attestation evidence and the BE/BS flags, never from the platform
name.

## Configuration

- `minSdk = 24` (Android 7.0), required for
  `KeyGenParameterSpec.setAttestationChallenge`.
- AppAuth redirect scheme is declared in
  `android/app/build.gradle.kts` (`appAuthRedirectScheme`) and
  `android/app/src/main/AndroidManifest.xml`.
- Network security config allows cleartext only for local development hosts.

## Registration flow

1. `GET /v1/projects/{projectId}/attestation/capabilities` — registration is
   blocked unless `android` is `implemented`.
2. `POST /v1/projects/{projectId}/devices/registration/challenge` — returns a
   single-use challenge (`challenge_id` + unpadded Base64url bytes).
3. The app decodes the Base64url challenge to raw bytes.
4. `MainActivity.kt` generates an EC P-256 key in Android Keystore with:
   - `setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))`
   - `setDigests(DIGEST_SHA256)`
   - `setAttestationChallenge(rawChallengeBytes)`
   - StrongBox when the device advertises it, falling back to the TEE.
5. The native side returns:
   - the public key as SPKI PEM,
   - the attestation certificate chain as PEM **leaf-first**,
   - a security level (`strongbox`, `trusted_environment`, `software`).
6. `POST /v1/projects/{projectId}/devices/registration/verify` submits the
   public key, key alias, algorithm `ES256`, and
   `evidence.certificate_chain`.
7. On success the key alias and device metadata are stored in secure storage.
   On failure the generated key is deleted so no orphan alias remains.

Gorape's verifier requires at least a leaf and issuer certificate, verifies the
chain against the configured Google roots, checks that the submitted public key
matches the leaf, and checks that the attestation challenge in the leaf's
Android key description matches the issued challenge.

## Possession proof

1. `POST /v1/projects/{projectId}/devices/{deviceId}/challenge`.
2. Decode the Base64url challenge to raw bytes.
3. Sign the raw bytes with `SHA256withECDSA` using the Keystore key.
4. Send the ASN.1/DER signature as unpadded Base64url to
   `POST .../devices/{deviceId}/verify`.

Gorape verifies with `ecdsa.VerifyASN1`, which is why the signature must remain
DER-encoded (do not convert it to raw `r || s`).

## Running on an emulator or device

The Android development defaults are:

- API: `https://api.gorapeflutter.site:8443` (local server; debug CA is loaded by the runner)
- OIDC issuer: `https://idp.gorapeflutter.site:9443/realms/gorape`
- WebAuthn RP ID: `gorapeflutter.site` (association files at the apex `/.well-known/`)

The issuer must match Keycloak's `iss` claim exactly. `*.gorapeflutter.site`
resolves to `127.0.0.1` in local development, and `adb reverse` forwards the
ports from the device to the developer host:

```bash
./scripts/run-android.sh
```

The script runs:

```bash
adb reverse tcp:8080 tcp:8080
adb reverse tcp:8000 tcp:8000
adb reverse tcp:8443 tcp:8443
adb reverse tcp:9443 tcp:9443
flutter run -d <device> --debug \
  --dart-define=GORAPE_API_BASE_URL=https://api.gorapeflutter.site:8443 \
  --dart-define=GORAPE_OIDC_ISSUER=https://idp.gorapeflutter.site:9443/realms/gorape
```

For local HTTPS, prefer `./scripts/run-android.sh`; it passes the generated CA
PEM to the debug Dart client. Also install that CA as a user certificate on the
Android device so native AppAuth and Chrome Custom Tabs can trust the Keycloak
TLS endpoint. The OIDC issuer must exactly match the discovery document's
`issuer` value.

Useful options:

```bash
./scripts/run-android.sh --device emulator-5554
./scripts/run-android.sh --api-url https://api.gorapeflutter.site:8443 --tls-ca config/generated/tls/ca.crt
./scripts/run-android.sh -- --verbose                      # extra flutter run args
```

Use the generated CA only for local development. Do not use it in release
builds; use a publicly trusted server certificate.

For a physical device without `adb reverse`, use the host's LAN IP for the API
**and** configure Keycloak with a matching hostname/issuer. Do not change only
the issuer host in the app unless Keycloak also issues tokens with that host.
The development domain can be replaced with any custom domain through
`--dart-define`; production must use a publicly trusted TLS certificate (never
disable certificate verification).

## Verifying registration

```bash
TOKEN=$(cat ../gorape/etc/.gorape/client/admin/access_token)
PROJECT_ID=805c5265-7315-420b-8aa7-3aea715ed88a

curl -s -H "Authorization: Bearer $TOKEN" \
  "http://api.gorapeflutter.site:8000/v1/projects/$PROJECT_ID/attestation/capabilities"

curl -s -H "Authorization: Bearer $TOKEN" \
  "http://api.gorapeflutter.site:8000/v1/projects/$PROJECT_ID/devices"

curl -s -H "Authorization: Bearer $TOKEN" \
  "http://api.gorapeflutter.site:8000/v1/projects/$PROJECT_ID/devices/<deviceId>/attestation"
```

A successful registration returns HTTP 201 and a device with
`platform: "android"`. The attestation record shows the verifier type, security
level, status, and the derived assurance level. Legacy Android Key Attestation
proves hardware key residency, so a `BE=false` credential can reach
`hardware_attested`; a WebAuthn passkey returns its own verified level.

### Physical Android-device PoC result

On a physical Android device running Android 17 (API 37), with GF Hardware Passkeys enabled, a Gorape
RP credential registered with HTTP 201. The persisted attestation record showed
`android-key`, `verified`, `trust_anchor`, `hardware_protected=true`,
`BE=false`, `BS=false`, and `assurance_level=hardware_attested`. A subsequent
passkey assertion was verified with HTTP 200. MDS was disabled in this test;
the configured Google Android Key Attestation root was used for certificate
chain validation. Typed-nil MDS provider handling for this mode is fixed under
[GF-10045](https://github.com/Gorapeflutter/gorape/blob/main/pkg/server/repository/webauthn.go#L291).

The persisted `security_level=android_key_attested` does not distinguish TEE
from StrongBox. The provider prefers StrongBox and falls back to TEE, but this
record alone does not prove which level generated the key. Keycloak login uses a
separate Google Password Manager credential for the `idp.gorapeflutter.site`
RP. CDA/hybrid remains unverified; the GF provider currently returns only the
`internal` transport.

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| Capabilities shows `android: unconfigured` | Server started without the generated trust anchors. Run `./scripts/generate-android-trust-config.sh`, then `./scripts/gorape-up.sh --android-attestation`. |
| Registration returns 422 `Android certificate chain` | Chain does not reach a configured Google root, is not leaf-first, or the device returns test/software attestation. |
| 422 `attested public key does not match` | The public key sent in `public_key_pem` is not the leaf certificate's key. Regenerate the key and retry. |
| 422 `attestation challenge` mismatch | The raw decoded challenge was not the exact value passed to `setAttestationChallenge`, or a stale challenge was reused. |
| `Android Key Attestation did not return a certificate chain` | The Keystore has no attestation support (common on emulators / some ROMs). Use a device with a hardware-backed Keystore. |
| Login opens Keycloak but returns `invalid_redirect_uri` | The Flutter redirect is not allow-listed. Fresh local realms import redirect URIs from `../gorape/etc/keycloak/gorape-realm.json`; add it manually to an existing realm's `gorape-client` if needed. |
| Login never opens the browser | Match the app's issuer to the Keycloak discovery document and install the local CA on Android for the HTTPS issuer. |
| Login succeeds but API returns 401 | The token issuer/audience must match `https://idp.gorapeflutter.site:9443/realms/gorape` and `gorape-api`. Check app settings and the Gorape project issuer. |
| `Cleartext HTTP traffic not permitted` | Only local development hosts are allow-listed in `network_security_config.xml`; use HTTPS or add the dev host. |
| Key exists but proof fails | The Keystore key may have been invalidated (lock screen change, restore, etc.). Revoke the device and register again. |
| Passkey registration returns `fmt=none` | Android Credential Manager may omit attestation even when `direct` is requested. The local strict test config rejects it; never infer hardware protection from the platform name. |

Emulators often produce software or test-rooted attestation. Passing Key
Attestation normally requires a physical Android device with a TEE/StrongBox
implementation that chains to Google's published roots.

## Limitations

- The legacy Android Key Attestation verifier is Android-only. iOS, macOS,
  Windows and Linux use the Gorape WebAuthn passkey ceremony, whose assurance is
  derived from verified attestation evidence (Apple, TPM, Android Key, or FIDO
  MDS).
- The app does not use Play Integrity; the Gorape contract is Android Key
  Attestation and WebAuthn attestation.
- Physical-device validation of Credential Manager `fmt=none`, Google root
  rotation, and release signing certificates is **unverified** in this
  environment. DAL currently contains debug fingerprints only.
- Device groups and policy enforcement are backend features that are not part of
  the current client/OpenAPI surface.
