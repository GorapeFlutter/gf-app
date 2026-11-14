# Android登録とattestation

実際の端末登録を行うplatformはAndroidのみです。backend verifierもAndroidのみ実装されています。

これはアプリ専用device keyに対するAndroid Key Attestationであり、WebAuthnパスキーattestationではありません。TPMとパスキーattestationの違いは[アーキテクチャ](ARCHITECTURE.md)を参照してください。

## 設定

- `minSdk = 24`（Android 7.0）。`KeyGenParameterSpec.setAttestationChallenge`に必要です。
- AppAuth redirect schemeは`android/app/build.gradle.kts`（`appAuthRedirectScheme`）と`android/app/src/main/AndroidManifest.xml`で宣言します。
- Network security configはlocal開発hostのみcleartext通信を許可します。

## 端末登録フロー

1. `GET /v1/projects/{projectId}/attestation/capabilities`を確認します。`android`が`implemented`でなければ登録できません。
2. `POST /v1/projects/{projectId}/devices/registration/challenge`で、一度だけ使えるchallenge（`challenge_id`とpaddingなしBase64url bytes）を取得します。
3. AppがBase64url challengeを生bytesにdecodeします。
4. `MainActivity.kt`がAndroid Keystore内にEC P-256鍵を生成します。
   - `setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))`
   - `setDigests(DIGEST_SHA256)`
   - `setAttestationChallenge(rawChallengeBytes)`
   - 端末が対応していればStrongBoxを使い、利用できない場合はTEEへfallbackします。
5. Native側が次を返します。
   - SPKI PEM形式の公開鍵
   - PEM形式のattestation certificate chain（leaf-first）
   - security level（`strongbox`、`trusted_environment`、`software`）
6. `POST /v1/projects/{projectId}/devices/registration/verify`で公開鍵、key alias、`ES256` algorithm、`evidence.certificate_chain`を送信します。
7. 成功時はkey aliasと端末metadataをsecure storageへ保存します。失敗時は孤立したaliasを残さないよう生成鍵を削除します。

Gorape verifierはleafとissuerを含む証明書chainを要求します。設定済みGoogle rootまでchainを検証し、送信された公開鍵がleafと一致すること、leafのAndroid key description内のattestation challengeが発行済みchallengeと一致することを検証します。

## 所有証明

1. `POST /v1/projects/{projectId}/devices/{deviceId}/challenge`でchallengeを取得します。
2. Base64url challengeを生bytesにdecodeします。
3. Keystore鍵で`SHA256withECDSA`署名します。
4. ASN.1/DER signatureを維持したままpaddingなしBase64urlにし、`POST .../devices/{deviceId}/verify`へ送ります。

Gorapeは`ecdsa.VerifyASN1`で検証します。signatureをraw `r || s`へ変換せず、DER形式のまま送信してください。

## Emulatorまたは端末での起動

Androidの既定値:

- API: `http://10.0.2.2:8000`（emulatorからhostへ接続するalias）
- OIDC issuer: `http://localhost:8080/realms/gorape`

IssuerはKeycloakがtokenに設定する`iss`と完全一致する必要があります。emulatorと実機の両方で利用する場合、APIとissuerの両方をlocalhostにして`adb reverse`を使う方法が簡単です。

```bash
./scripts/run-android.sh
```

このscriptは次を実行します。

```bash
adb reverse tcp:8080 tcp:8080
adb reverse tcp:8000 tcp:8000
flutter run -d <device> --debug \
  --dart-define=GORAPE_API_BASE_URL=http://localhost:8000 \
  --dart-define=GORAPE_OIDC_ISSUER=http://localhost:8080/realms/gorape
```

便利なoption:

```bash
./scripts/run-android.sh --device emulator-5554
./scripts/run-android.sh --api-url http://10.0.2.2:8000   # APIにadb reverseを使わないemulator
./scripts/run-android.sh --release
./scripts/run-android.sh -- --verbose                      # flutter runへ追加引数を渡す
```

実機で`adb reverse`を使わない場合、APIにはhostのLAN IPを指定し、Keycloakも一致するhostname/issuerで設定します。Keycloakが別hostの`iss`を発行しない限り、App側のissuerだけを変更しないでください。

## 登録の確認

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

登録成功時はHTTP 201と`platform: "android"`のdeviceが返ります。attestation recordにはverifier type、security level、statusが含まれます。

## Troubleshooting

| 症状 | 原因 / 対処 |
| --- | --- |
| Capabilitiesが`android: unconfigured` | 生成trust anchorなしでserverを起動しています。`./scripts/generate-android-trust-config.sh`を実行後、`./scripts/gorape-up.sh --android-attestation`で起動します。 |
| 登録が422 `Android certificate chain` | chainが設定済みGoogle rootに到達しない、leaf-firstでない、または端末がtest/software attestationを返しています。 |
| 422 `attested public key does not match` | `public_key_pem`の公開鍵がleaf certificateの鍵と一致しません。鍵を再生成して再試行します。 |
| 422 `attestation challenge` mismatch | decodeしたchallengeが`setAttestationChallenge`へ渡したbytesと異なるか、古いchallengeを再利用しています。 |
| `Android Key Attestation did not return a certificate chain` | Keystoreがattestationに対応していない可能性があります（emulatorや一部ROMなど）。hardware-backed Keystore搭載端末を使います。 |
| Login後に`invalid_redirect_uri` | Flutter redirectがallow listにありません。`./scripts/keycloak-allow-redirect.sh`を実行します。 |
| Login成功後にAPIが401 | token issuer/audienceが`http://localhost:8080/realms/gorape`と`gorape-api`に一致する必要があります。接続設定を確認します。 |
| `Cleartext HTTP traffic not permitted` | `network_security_config.xml`で許可されたlocal開発host以外を使っています。HTTPSにするか開発hostを追加します。 |
| 鍵はあるがproofに失敗 | 画面lock変更やrestoreなどでKeystore鍵が無効化された可能性があります。deviceを失効して再登録します。 |

Emulatorはsoftwareまたはtest rootのattestationを返す場合があります。Key Attestationを通過するには、Google公開rootへchainするTEE/StrongBox実装を持つ実機が必要になることがあります。

## 制限

- backendにiOS/macOS/Windows verifierがないため、各platformはKeycloak loginまでで、unsupported状態を表示します。
- Play Integrityは使いません。Gorape contractはAndroid Key Attestationです。
- 現在のclient/OpenAPI surfaceにはdevice group管理とpolicy enforcementは含まれていません。
