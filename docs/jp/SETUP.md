# Backend、Keycloak、Dockerのセットアップ

`gf-app`はGorape backend repositoryが提供するDocker Compose環境を利用します。backend checkoutは変更せず、このrepositoryでは`docker/`のoverrideと`scripts/`による起動処理だけを追加します。

## Repositoryの配置

```text
Gorapeflutter/
  gorape/     backend checkout。docker/*.yamlとetc/server.yaml.dockerを管理
  gf-app/     このFlutter client
```

別の場所にあるbackendを使う場合は環境変数を設定します。

```bash
export GORAPE_BACKEND_DIR=/absolute/path/to/gorape
```

## Composeの構成

`scripts/lib.sh`はbackendの`Makefile`と同じComposeファイルから開始します。

```text
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

その後、gf-appのoverrideを追加します。

- `docker/server.image.yaml` — local buildの代わりにDocker Hub imageを使用します。
- `docker/server.android-attestation.yaml` — Google Android Key Attestation rootを含む生成済みserver configをmountします。

`docker/server.android-attestation.yaml`はComposeの`!override` tagでserverの`volumes`一覧を置き換えるため、元の`docker/server.yaml`は変更されません。Compose v2.24以降が必要です。

## Legacy Android Keystore trust anchor

Gorape Android verifierはcontainer内の`Application.Server.Attestation.android_trust_anchors`を読みます。標準設定では一覧が空のため、`GET /v1/projects/{projectId}/attestation/capabilities`は`android: "unconfigured"`を返し、登録はHTTP 422で失敗します。

Googleが公開しているrootを参照する設定を生成します。

```bash
./scripts/generate-android-trust-config.sh
```

このscriptは`https://android.googleapis.com/attestation/root`をdownloadし、`openssl`があればcertificateを検証して、次を生成します。

```text
config/generated/android-attestation-roots.pem
config/generated/server.yaml
```

`server.yaml`は`gorape/etc/server.yaml.docker`のattestation設定のみを変更したcopyです。

```yaml
attestation: {android_trust_anchors: ["/app/etc/android/android-attestation-roots.pem"]}
```

Compose overrideは生成ファイルを次のcontainer pathへmountします。

```text
config/generated/server.yaml                      -> /app/etc/server.yaml
config/generated/android-attestation-roots.pem    -> /app/etc/android/android-attestation-roots.pem
```

独自root bundle（private enterprise CAなど）は`--source FILE_OR_URL`で指定できます。Googleがrootを更新した場合は再生成し、`./scripts/gorape-up.sh --android-attestation`でserverを再起動してください。

### Verifierの稼働確認

```bash
curl -s http://localhost:8000/health

TOKEN=$(cat ../gorape/etc/.gorape/client/admin/access_token)
PROJECT_ID=$(curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/v1/projects | python3 -c \
  'import json,sys; print(json.load(sys.stdin)[0]["id"])')

curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/v1/projects/$PROJECT_ID/attestation/capabilities"
```

期待されるresponse:

```json
{"verifiers":{"android":"implemented","ios":"unsupported","macos":"unsupported","windows":"unsupported"}}
```

tokenがない場合はbackend CLIをbuildして使います。

```bash
cd ../gorape
make build
.bin/gorape-client -c etc/app.yaml login
cat etc/.gorape/client/admin/access_token
```

CLIは同じ`gorape-client`とredirect URI `http://127.0.0.1:8400/callback`を使います。

## Gorape RP用passkey/attestation

端末登録画面はKeycloak passkeyとは別のGorape RP用WebAuthn ceremonyを実行します。Gorape RP IDはapp buildや認証器とのdomain associationに関わるため、環境間で安易に変更しないでください。

Backend configの例:

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

ローカルDockerのRP IDを設定し、Android debug signing key由来の`android:apk-key-hash` originを許可します。ローカル試験用にattestation `none`を許可します。Organization Pages repositoryが`/.well-known/assetlinks.json`を公開し、Android package `com.gorapeflutter.gf_app`とdebug signing certificateを`delegate_permission/common.get_login_creds`および`delegate_permission/common.handle_all_urls`で関連付けます。API接続先は引き続き`https://localhost:8443`で、RP domainとは別です。API用のローカルCAはDigital Asset Linksに使いません。

Backend実装では[GF-10010](https://github.com/Gorapeflutter/gorape/blob/main/pkg/server/repository/webauthn.go#L88)〜[GF-10011](https://github.com/Gorapeflutter/gorape/blob/main/pkg/server/repository/webauthn.go#L605)がRP identityを検証し、[GF-10016](https://github.com/Gorapeflutter/gorape/blob/main/pkg/server/usecase/passkey_device.go#L91)〜[GF-10017](https://github.com/Gorapeflutter/gorape/blob/main/pkg/server/usecase/passkey_device.go#L151)がregistration options発行とcredential検証を行います。
Backend IDの一覧は[Gorape source index](https://github.com/Gorapeflutter/gorape/blob/main/docs/book/src/source-index.md)を参照してください。

別のAndroid debug signing keyを使う場合は、Pagesの`assetlinks.json`へSHA-256 certificate fingerprintを追加し、`../gorape/etc/server.yaml.docker`の`webauthn.rp_origins`へ対応する`android:apk-key-hash:`を追加します。その後Pagesを再deployし、server configを再生成してください。

ローカルAPIにもHTTPS listenerを追加する場合（Android RP domain検証とは別です）：

```bash
./scripts/generate-local-tls.sh [--host <ローカルDNS名>]
./scripts/gorape-up.sh --https --android-attestation
curl --cacert config/generated/tls/ca.crt https://localhost:8443/health
```

ローカルCAと証明書はGit管理対象外の`config/generated/tls/`に生成され、秘密鍵はmode `0600`です。このCAを本番のtrust anchorとして使わないでください。`./scripts/run-android.sh`はdebug Dart clientにこのCAを渡し、API URLを`https://localhost:8443`にします。Android native passkeyのRP関連付けは、別途GitHub Pagesの公開DALで行います。

既定は`allowed_formats: []`、`allow_none: false`、`allow_self_attestation: false`で、RPまたはpolicyの未設定時は登録を拒否します。独自trust anchorはserver containerへmountし、container内のpathをconfigへ指定してください。`android-key`のtrust anchorは、明示設定がなければlegacy `android_trust_anchors`を再利用します。

各platformで同一RP IDへのassociationが必要です。

- **Android:** `https://<rp-id>/.well-known/assetlinks.json`に`delegate_permission/common.get_login_creds`と`delegate_permission/common.handle_all_urls`、package name、debug/release/Play signing certificateのSHA-256 fingerprintsを設定します。
- **iOS/macOS:** AASAの`webcredentials`にTeam ID + bundle IDを設定し、アプリのAssociated Domains entitlementへ`webcredentials:<rp-id>`を追加します。
- **Web:** secure originでserveし、RP IDをpage hostまたは親domainにします。
- **Windows:** Windows WebAuthn APIを利用します。TPM attestationがOS/providerから返る保証はありません。
- **Linux:** `passkeys` pluginは未対応ですが、gf-appのWeb ceremony pageをChrome/Firefoxで開きます。Gorape本体はUIを提供せず、APIのみです。

`rp_origins`は完全一致のallowlistです。HTTPS originはRP ID配下、HTTPはlocalhost開発のみ、Android native originは`android:apk-key-hash:`の完全な値を登録してください。wildcardは使用できません。Linux browser ceremony pageはgf-app web buildに含まれ、`portal_origin`から配信します。`portal_origin`は`rp_origins`と`web_origins`の両方に登録し、`browser_api_origin`はgf-appのAPI URLと一致させます。Gorape本体はAPIのみで、end-user画面を持ちません。Linux buildには`desktop_webview_window`のGTK/WebKitGTK development librariesが必要ですが、実行時はChrome/Firefox等のsystem browserを使います。`direct`はattestationを要求するpreferenceで、返却を保証しません。Gorapeは応答内の実際のformatとtrust chainを検証します。

### Native Device Trust鍵

gf-appはAndroid Keystore、Apple Secure Enclave、Windows Platform Crypto Provider、Linux TPM2のOS別Device鍵providerを持ちます。Linuxのruntime key操作には`/dev/tpmrm0`へのaccessと`tpm2-tools`が必要で、device TCTIを固定しsoftware keyへfallbackしません。Apple/Windows/Linuxのlegacy生鍵providerは現状server検証可能な同一鍵Attestationを送らないため、WebAuthn経路（`PasskeyDeviceUsecase`）を主経路として利用します。

## Keycloak

| 項目 | 値 |
| --- | --- |
| Issuer | `http://localhost:8080/realms/gorape` |
| Client | `gorape-client`（public） |
| Flow | Authorization Code + PKCE S256 |
| Scope | `openid profile` |
| Audience | `gorape-api`（専用audience mapper） |
| CLI redirect | `http://127.0.0.1:8400/callback`（維持） |
| Android/iOS/macOS redirect | `com.gorapeflutter.gfapp:/oauth2redirect` |
| Windows/Linux redirect | `http://127.0.0.1:8401/oauth2redirect` |
| Web redirect | 同一originの`/auth.html`（local devは`http://localhost:5000/auth.html`） |

新規ローカルDBでは、Flutter redirect/passwordless WebAuthn/パスキー専用ログインフロー/`gorape-passkey-amr` mapper/登録Required Actionを`../gorape/etc/keycloak/gorape-realm.json`からimportします。「Keycloakパスキーを登録」はWebAuthn Passwordless AIAを使います。「パスキーでログイン」はユーザー名・パスワード欄のない専用フローを要求します。成功したWebAuthn executionが`amr: ["passkey"]`を発行し、Gorapeはこの署名済みclaimがある場合のみデバイス登録・所有証明を許可します。

ローカルPostgres containerはschema migration後に`../gorape/scripts/data/postgres/004-gorape-demo-seed.sql`を読み込み、`demo` projectと権限テスト用fixtureを作成します。ローカル環境では`gorape-admin provision apply`は不要です。これらは新規DB初期化時のみ適用されます。tmpfs Postgres containerを再作成するとKeycloak userと登録済みpasskeyも初期化されます。

既存realmではKeycloak Admin Console → realm `gorape` → Clients → `gorape-client`からFlutter redirect URI/Web Originsを追加し、CLI callbackは残してください。Local Webは`flutter run -d chrome --web-port=5000`で起動します。

Keycloak/Postgres dataを削除するとrealmとdemo fixtureは設定ファイルから再importされます。test passwordは`../gorape/etc/README.md`を参照し、端末passkeyは再登録してください。

Realmはnative custom scheme、desktop loopback、同一origin Web callbackに対応します。redirect URIがallow listにあればAuthorization Code + PKCEを開始できます。appにclient secretは保存しません。

## 起動と停止

```bash
./scripts/gorape-up.sh                        # local build、基本service
./scripts/gorape-up.sh --android-attestation  # + 生成済みtrust anchor
./scripts/gorape-up.sh --all                  # + pgadmin/swagger/godoc/localstack
./scripts/gorape-up.sh --server-only          # 依存service起動済みの場合はAPIのみ
./scripts/gorape-up.sh --hub TAG --pull       # 公開image

./scripts/gorape-down.sh                      # container停止、volume維持
./scripts/gorape-down.sh --server             # API containerのみ削除
./scripts/gorape-down.sh --volumes            # 破壊的操作: dataを削除
```

開発環境のport:

| Service | URL |
| --- | --- |
| Gorape API | http://localhost:8000 |
| Health | http://localhost:8000/health |
| Keycloak | http://localhost:8080 |
| Keycloak admin | http://localhost:8080/admin |
| pgAdmin | http://localhost:3001 |
| Swagger UI（任意） | http://localhost:3002 |

開発用credentialはbackend repositoryで管理されます。

- Keycloak admin: `admin` / `admin`
- Seed済みrealm user: `gorape/etc/keycloak/gorape-realm.json`を参照（`gorape-admin`の仮passwordは`ChangeMe123!`）

いずれもlocal開発専用です。

## 公開image override

`docker/server.image.yaml`:

```yaml
services:
  server:
    image: ${GORAPE_SERVER_IMAGE:-gorapeflutter/gorape:latest}
    build: !reset null
```

`!reset`でbackend Composeから継承した`build`を削除し、imageを使います。再現性のため`sha-…` tagまたはdigestを指定してください。`latest` tagは随時更新されます。

`--android-attestation`も使う場合、生成される`server.yaml`はlocal backend checkoutを元に作られます。mountするconfigとimageのschemaを合わせるため、checkoutとpinned imageは同じreleaseにしてください。

## Troubleshooting

- **`error: duplicate mount point /app/etc/server.yaml`** — Composeがv2.24未満です。upgradeするか、生成overrideを外してbackend標準configを使います。
- **`Missing …/config/generated/server.yaml`** — 先に`./scripts/generate-android-trust-config.sh`を実行します。`--android-attestation`指定時は生成された2ファイルが必要です。
- **Capabilitiesが`unconfigured`のまま** — attestation overrideなしでserverを起動しています。`./scripts/gorape-up.sh --android-attestation --no-build`で再起動し、`docker inspect gorape --format '{{json .Mounts}}'`でmountを確認します。
- **Keycloakが`invalid_redirect_uri`を返す** — 新規ローカルDBでは`../gorape/etc/keycloak/gorape-realm.json`のclient importを確認します。既存realmではAdmin Consoleでredirect URIを追加し、CLI URIは残してください。
- **volume削除後にbackendが起動しない** — 初回boot時のrealm importには最大1分かかる場合があります。health waitを再実行するか`docker logs gorape-keycloak`を確認します。
