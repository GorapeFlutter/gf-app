# Android registration and attestation

Android is the only platform where this client performs real device
registration. The backend verifier is implemented for Android only.

This is Android Key Attestation for an app-generated device key, not WebAuthn
passkey attestation. See the [architecture chapter](ARCHITECTURE.md) for the
TPM and passkey-attestation comparison.

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

The Android defaults are:

- API: `http://10.0.2.2:8000` (emulator host alias)
- OIDC issuer: `http://localhost:8080/realms/gorape`

The issuer must match Keycloak's `iss` claim exactly. The simplest setup that
works on both emulators and physical devices is `adb reverse` plus localhost for
both endpoints:

```bash
./scripts/run-android.sh
```

The script runs:

```bash
adb reverse tcp:8080 tcp:8080
adb reverse tcp:8000 tcp:8000
flutter run -d <device> --debug \
  --dart-define=GORAPE_API_BASE_URL=http://localhost:8000 \
  --dart-define=GORAPE_OIDC_ISSUER=http://localhost:8080/realms/gorape
```

Useful options:

```bash
./scripts/run-android.sh --device emulator-5554
./scripts/run-android.sh --api-url http://10.0.2.2:8000   # emulator without reverse for the API
./scripts/run-android.sh --release
./scripts/run-android.sh -- --verbose                      # extra flutter run args
```

For a physical device without `adb reverse`, use the host's LAN IP for the API
**and** configure Keycloak with a matching hostname/issuer. Do not change only
the issuer host in the app unless Keycloak also issues tokens with that host.

## Verifying registration

```bash
TOKEN=$(cat ../gorape/etc/.gorape/client/admin/access_token)
PROJECT_ID=805c5265-7315-420b-8aa7-3aea715ed88a

curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/v1/projects/$PROJECT_ID/attestation/capabilities"

curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/v1/projects/$PROJECT_ID/devices"

curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/v1/projects/$PROJECT_ID/devices/<deviceId>/attestation"
```

A successful registration returns HTTP 201 and a device with
`platform: "android"`. The attestation record shows the verifier type, security
level and status.

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| Capabilities shows `android: unconfigured` | Server started without the generated trust anchors. Run `./scripts/generate-android-trust-config.sh`, then `./scripts/gorape-up.sh --android-attestation`. |
| Registration returns 422 `Android certificate chain` | Chain does not reach a configured Google root, is not leaf-first, or the device returns test/software attestation. |
| 422 `attested public key does not match` | The public key sent in `public_key_pem` is not the leaf certificate's key. Regenerate the key and retry. |
| 422 `attestation challenge` mismatch | The raw decoded challenge was not the exact value passed to `setAttestationChallenge`, or a stale challenge was reused. |
| `Android Key Attestation did not return a certificate chain` | The Keystore has no attestation support (common on emulators / some ROMs). Use a device with a hardware-backed Keystore. |
| Login opens Keycloak but returns `invalid_redirect_uri` | The Flutter redirect is not allow-listed. Run `./scripts/keycloak-allow-redirect.sh`. |
| Login succeeds but API returns 401 | The token issuer/audience must match `http://localhost:8080/realms/gorape` and `gorape-api`. Check the app's connection settings. |
| `Cleartext HTTP traffic not permitted` | Only local development hosts are allow-listed in `network_security_config.xml`; use HTTPS or add the dev host. |
| Key exists but proof fails | The Keystore key may have been invalidated (lock screen change, restore, etc.). Revoke the device and register again. |

Emulators often produce software or test-rooted attestation. Passing Key
Attestation normally requires a physical Android device with a TEE/StrongBox
implementation that chains to Google's published roots.

## Limitations

- The backend has no iOS/macOS/Windows verifier, so those platforms stop at
  Keycloak login and display an explicit unsupported state.
- The app does not use Play Integrity; the Gorape contract is Android Key
  Attestation.
- Device groups and policy enforcement are backend features that are not part of
  the current client/OpenAPI surface.
