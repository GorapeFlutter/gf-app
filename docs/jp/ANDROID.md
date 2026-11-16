# Android登録とattestation

Androidの主要な端末登録経路はGorape RPのWebAuthnパスキーceremonyです。この章は互換性のためbackend verifierが維持しているlegacy Android Key Attestationフローを説明します。

legacy Android Key Attestationはアプリ専用device keyに対するattestationであり、WebAuthnパスキーattestationではありません。TPMとパスキーattestationの違いは[アーキテクチャ](ARCHITECTURE.md)を参照してください。パスキーの保証レベル（`hardware_attested`、`device_bound_unattested`、`standard_passkey`、`rejected`）は、platform名ではなく検証済みattestation証拠とBE/BSフラグからGorapeが導出します。

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

Android開発環境の既定値:

- API: `https://api.gorapeflutter.site:8443`（local server。debug runnerが開発CAを設定）
- OIDC issuer: `https://idp.gorapeflutter.site:9443/realms/gorape`
- WebAuthn RP ID: `gorapeflutter.site`（association fileはapexの`/.well-known/`）

IssuerはKeycloakがtokenに設定する`iss`と完全一致する必要があります。ローカル開発では`*.gorapeflutter.site`が`127.0.0.1`に解決され、`adb reverse`が端末から開発hostへportを転送します。

```bash
./scripts/run-android.sh
```

このscriptは次を実行します。

```bash
adb reverse tcp:8080 tcp:8080
adb reverse tcp:8000 tcp:8000
adb reverse tcp:8443 tcp:8443
adb reverse tcp:9443 tcp:9443
flutter run -d <device> --debug \
  --dart-define=GORAPE_API_BASE_URL=https://api.gorapeflutter.site:8443 \
  --dart-define=GORAPE_OIDC_ISSUER=https://idp.gorapeflutter.site:9443/realms/gorape
```

ローカルHTTPSでは`./scripts/run-android.sh`を使ってください。生成CAのPEMをdebug Dart clientへ渡します。AndroidのAppAuthとChrome Custom TabでもKeycloakへ接続するため、生成CAを端末のユーザー証明書として一度インストールしてください。IssuerはKeycloak discoveryの`issuer`と完全一致する必要があります。

便利なoption:

```bash
./scripts/run-android.sh --device emulator-5554
./scripts/run-android.sh --api-url https://api.gorapeflutter.site:8443 --tls-ca config/generated/tls/ca.crt
./scripts/run-android.sh -- --verbose                      # flutter runへ追加引数を渡す
```

生成CAはローカル開発端末でのみ信頼してください。release buildでは開発CAを使わず、公的に信頼されたserver certificateを使用してください。開発domainは`--dart-define`で任意の独自domainへ変更できますが、本番でTLS証明書検証を無効化してはいけません。

実機で`adb reverse`を使わない場合、APIにはhostのLAN IPを指定し、Keycloakも一致するhostname/issuerで設定します。Keycloakが別hostの`iss`を発行しない限り、App側のissuerだけを変更しないでください。

## 登録の確認

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

登録成功時はHTTP 201と`platform: "android"`のdeviceが返ります。attestation recordにはverifier type、security level、status、導出された保証レベルが含まれます。legacy Android Key Attestationはハードウェア鍵の常在を証明するため、`BE=false`のcredentialは`hardware_attested`になり得ます。WebAuthnパスキーは独自の検証済みレベルを返します。

### Android実機PoCの検証結果

Android 17 (API 37) の実機でGF Hardware Passkeysを有効にし、Gorape RP用credentialを登録しました。Gorapeはregistration verifyでHTTP 201を返し、DBのattestation recordは`android-key`、`verified`、`trust_anchor`、`hardware_protected=true`、`BE=false`、`BS=false`、`assurance_level=hardware_attested`でした。続くpasskey assertionもHTTP 200で検証されています。検証用設定ではMDSは無効で、Google Android Key Attestation trust anchorによるchain検証を使いました。

DBの`security_level=android_key_attested`はTEE/StrongBoxを区別しません。実装はStrongBoxを優先し、利用できない場合はTEEへfallbackしますが、この登録結果だけからどちらのlevelかは断定しません。Keycloakログイン用パスキーは別RP (`idp.gorapeflutter.site`) のGoogle Password Manager credentialであり、このGF Providerの検証対象ではありません。CDA/hybridは未検証で、現在のProviderは`internal`のみを返します。

## Troubleshooting

| 症状 | 原因 / 対処 |
| --- | --- |
| Capabilitiesが`android: unconfigured` | 生成trust anchorなしでserverを起動しています。`./scripts/generate-android-trust-config.sh`を実行後、`./scripts/gorape-up.sh --android-attestation`で起動します。 |
| 登録が422 `Android certificate chain` | chainが設定済みGoogle rootに到達しない、leaf-firstでない、または端末がtest/software attestationを返しています。 |
| 422 `attested public key does not match` | `public_key_pem`の公開鍵がleaf certificateの鍵と一致しません。鍵を再生成して再試行します。 |
| 422 `attestation challenge` mismatch | decodeしたchallengeが`setAttestationChallenge`へ渡したbytesと異なるか、古いchallengeを再利用しています。 |
| `Android Key Attestation did not return a certificate chain` | Keystoreがattestationに対応していない可能性があります（emulatorや一部ROMなど）。hardware-backed Keystore搭載端末を使います。 |
| Login後に`invalid_redirect_uri` | Flutter redirectがallow listにありません。新規ローカルrealmは`../gorape/etc/keycloak/gorape-realm.json`からimportされます。既存realmでは`gorape-client`へ手動追加します。 |
| ブラウザー起動前にログインが進まない | 接続設定のIssuerをKeycloak discoveryの`issuer`に合わせ、ローカルHTTPSでは生成CAをAndroidのユーザー証明書としてインストールします。 |
| Login成功後にAPIが401 | token issuer/audienceが`https://idp.gorapeflutter.site:9443/realms/gorape`と`gorape-api`に一致する必要があります。接続設定とGorape project issuerを確認します。 |
| `Cleartext HTTP traffic not permitted` | `network_security_config.xml`で許可されたlocal開発host以外を使っています。HTTPSにするか開発hostを追加します。 |
| 鍵はあるがproofに失敗 | 画面lock変更やrestoreなどでKeystore鍵が無効化された可能性があります。deviceを失効して再登録します。 |
| パスキー登録が`fmt=none`を返す | `direct`を要求してもAndroid Credential Managerがattestation statementを返さない場合があります。ローカルのstrict test設定では拒否します。platform名からハードウェア保護を推定してはいけません。 |

Emulatorはsoftwareまたはtest rootのattestationを返す場合があります。Key Attestationを通過するには、Google公開rootへchainするTEE/StrongBox実装を持つ実機が必要になることがあります。

## 制限

- legacy Android Key Attestation verifierはAndroid専用です。iOS、macOS、Windows、LinuxはGorape WebAuthnパスキーceremonyを使い、保証レベルは検証済みattestation証拠（Apple、TPM、Android Key、FIDO MDS）から導出します。
- Play Integrityは使いません。Gorape contractはAndroid Key AttestationとWebAuthn attestationです。
- Credential Managerの`fmt=none`、Google root更新、release署名証明書の実機検証はこの環境では**未検証**です。DALは現状debug fingerprintのみを含みます。
- 現在のclient/OpenAPI surfaceにはdevice group管理とpolicy enforcementは含まれていません。
