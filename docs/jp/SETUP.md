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

## Android trust anchor

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

## Keycloak

| 項目 | 値 |
| --- | --- |
| Issuer | `http://localhost:8080/realms/gorape` |
| Client | `gorape-client`（public） |
| Flow | Authorization Code + PKCE S256 |
| Scope | `openid profile` |
| Audience | `gorape-api`（専用audience mapper） |
| CLI redirect | `http://127.0.0.1:8400/callback`（維持） |
| Flutter redirect | `com.gorapeflutter.gfapp:/oauth2redirect` |

CLI redirectを残したままFlutter redirectを追加します。

```bash
./scripts/keycloak-allow-redirect.sh
```

このscriptはKeycloak Admin API（既定値は`admin` / `admin`）を使い、URI一覧をmergeします。また`pkce.code.challenge.method=S256`を設定し、`post.logout.redirect.uris=+`を維持します。何度実行しても結果は同じです。現在のclientは`--show`で確認できます。

手動で設定する場合: Keycloak Admin Console → realm `gorape` → Clients → `gorape-client` → Valid redirect URIsに`com.gorapeflutter.gfapp:/oauth2redirect`を追加します。CLI URIは削除しないでください。

> このscriptが変更するのは稼働中のKeycloak databaseだけです。backendのrealm import file（`etc/keycloak/gorape-realm.json`）は変更しません。`./scripts/gorape-down.sh --volumes`でKeycloak volumeを削除すると、Flutter URIなしでrealmが再importされるためscriptを再実行してください。永続化する場合は、意図を確認したうえでbackend realm JSONにもURIを追加します。

Realmはnative app用custom schemeにも対応しています。redirect URIがallow listにあればauth endpointが受け付けます。PKCE必須のため、appにclient secretは保存しません。

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
- **Keycloakが`invalid_redirect_uri`を返す** — `./scripts/keycloak-allow-redirect.sh`を実行し、`--show`の結果を確認します。
- **volume削除後にbackendが起動しない** — 初回boot時のrealm importには最大1分かかる場合があります。health waitを再実行するか`docker logs gorape-keycloak`を確認します。
