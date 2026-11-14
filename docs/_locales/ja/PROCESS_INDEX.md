# 関数内処理ステップID一覧

[GF-02000](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/auth.dart#L48)以降は、複数段階の関数に含まれる主要な処理ステップを示します。個々の文ではなく、意味のある処理境界に付けたIDです。ソースコード中の英語コメントと照合できます。

| ID | 処理ステップ | ソース |
| --- | --- | --- |
| [GF-02000](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/auth.dart#L48) | Secure Storageに保存されたtokenを読み、decodeする | `lib/usecase/auth.dart` |
| [GF-02001](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/auth.dart#L55) | 不正なsessionデータを削除する | `lib/usecase/auth.dart` |
| [GF-02002](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/auth.dart#L59) | 有効なaccess tokenを持つsessionを再利用する | `lib/usecase/auth.dart` |
| [GF-02003](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/auth.dart#L63) | 期限切れsessionをrefreshし、新しいtokenを保存する | `lib/usecase/auth.dart` |
| [GF-02004](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/auth.dart#L71) | refreshできない期限切れsessionを削除する | `lib/usecase/auth.dart` |
| [GF-02005](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/auth.dart#L79) | OIDC非対応platformでのsign-inを拒否する | `lib/usecase/auth.dart` |
| [GF-02006](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/auth.dart#L85) | Authorization Code + PKCEでsign-inする | `lib/usecase/auth.dart` |
| [GF-02007](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/auth.dart#L87) | 認証済みsessionを返す前にtokenを保存する | `lib/usecase/auth.dart` |
| [GF-02008](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/auth.dart#L95) | adapterまたはrefresh tokenがない場合に更新を省略する | `lib/usecase/auth.dart` |
| [GF-02009](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/auth.dart#L98) | tokenをrefreshし、新しいtokenを保存する | `lib/usecase/auth.dart` |
| [GF-02010](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/auth.dart#L110) | 対応platformのremote sessionをproviderからsign-outする | `lib/usecase/auth.dart` |
| [GF-02011](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/auth.dart#L114) | remote sign-out後にローカルsessionを削除する | `lib/usecase/auth.dart` |
| [GF-02012](https://github.com/Gorapeflutter/gf-app/blob/main/lib/repository/gorape.dart#L538) | API URI、JSON body、request headerを組み立てる | `lib/repository/gorape.dart` |
| [GF-02013](https://github.com/Gorapeflutter/gf-app/blob/main/lib/repository/gorape.dart#L549) | 最初のAPI requestを送信する | `lib/repository/gorape.dart` |
| [GF-02014](https://github.com/Gorapeflutter/gf-app/blob/main/lib/repository/gorape.dart#L557) | 期限切れaccess tokenのrefreshを一度だけ試す | `lib/repository/gorape.dart` |
| [GF-02015](https://github.com/Gorapeflutter/gf-app/blob/main/lib/repository/gorape.dart#L565) | 新しいtokenで元のAPI requestを一度だけ再試行する | `lib/repository/gorape.dart` |
| [GF-02016](https://github.com/Gorapeflutter/gf-app/blob/main/lib/repository/gorape.dart#L574) | 成功したJSON responseをdecodeする | `lib/repository/gorape.dart` |
| [GF-02017](https://github.com/Gorapeflutter/gf-app/blob/main/lib/repository/gorape.dart#L582) | HTTP errorをアプリケーション例外へ変換する | `lib/repository/gorape.dart` |
| [GF-02018](https://github.com/Gorapeflutter/gf-app/blob/main/lib/repository/gorape.dart#L606) | HTTP methodに応じてrequestを振り分ける | `lib/repository/gorape.dart` |
| [GF-02019](https://github.com/Gorapeflutter/gf-app/blob/main/lib/repository/gorape.dart#L615) | request timeoutをnetwork errorへ変換する | `lib/repository/gorape.dart` |
| [GF-02020](https://github.com/Gorapeflutter/gf-app/blob/main/lib/repository/gorape.dart#L622) | HTTP clientの接続失敗をnetwork errorへ変換する | `lib/repository/gorape.dart` |
| [GF-02021](https://github.com/Gorapeflutter/gf-app/blob/main/lib/repository/gorape.dart#L636) | JSONから構造化されたAPI error情報を読む | `lib/repository/gorape.dart` |
| [GF-02022](https://github.com/Gorapeflutter/gf-app/blob/main/lib/repository/gorape.dart#L647) | 認証拒否errorに確認事項を付加する | `lib/repository/gorape.dart` |
| [GF-02023](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L96) | 登録名を正規化し、入力を検証する | `lib/usecase/device.dart` |
| [GF-02024](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L106) | 端末側のOS鍵・attestation対応状況を確認する | `lib/usecase/device.dart` |
| [GF-02025](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L116) | backend verifierが設定済みであることを確認する | `lib/usecase/device.dart` |
| [GF-02026](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L119) | 一度だけ使える登録challengeを要求する | `lib/usecase/device.dart` |
| [GF-02027](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L131) | decodeしたchallengeを新しいOS鍵に結び付ける | `lib/usecase/device.dart` |
| [GF-02028](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L148) | 公開鍵とattestation evidenceを送信する | `lib/usecase/device.dart` |
| [GF-02029](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L171) | server検証成功後にローカルkey aliasを保存する | `lib/usecase/device.dart` |
| [GF-02030](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L179) | 登録失敗時に生成した鍵を削除する | `lib/usecase/device.dart` |
| [GF-02031](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L196) | 登録済みローカル秘密鍵を読み、利用可能か確認する | `lib/usecase/device.dart` |
| [GF-02032](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L210) | 新しい所有証明challengeを要求する | `lib/usecase/device.dart` |
| [GF-02033](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L220) | OS key store内でchallengeの生bytesに署名する | `lib/usecase/device.dart` |
| [GF-02034](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L231) | 署名をserver検証へ送信する | `lib/usecase/device.dart` |
| [GF-02035](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L250) | backendの正本であるdevice recordを失効する | `lib/usecase/device.dart` |
| [GF-02036](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L254) | ローカル鍵とmetadataをbest-effortで削除する | `lib/usecase/device.dart` |
| [GF-02037](https://github.com/Gorapeflutter/gf-app/blob/main/lib/app.dart#L47) | platform、設定、認証stateを読み解く | `lib/app.dart` |
| [GF-02038](https://github.com/Gorapeflutter/gf-app/blob/main/lib/app.dart#L53) | 設定読み込み中にsplash screenを表示する | `lib/app.dart` |
| [GF-02039](https://github.com/Gorapeflutter/gf-app/blob/main/lib/app.dart#L57) | retry操作を付けて接続設定errorを表示する | `lib/app.dart` |
| [GF-02040](https://github.com/Gorapeflutter/gf-app/blob/main/lib/app.dart#L78) | 認証済みsessionをapp shellへ遷移させる | `lib/app.dart` |
| [GF-02041](https://github.com/Gorapeflutter/gf-app/blob/main/lib/app.dart#L89) | platformと設定を渡してlogin screenを構築する | `lib/app.dart` |
| [GF-02042](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/device.dart#L98) | Controller経由で端末登録usecaseを実行する | `lib/controller/device.dart` |
| [GF-02043](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/device.dart#L102) | 登録後にdeviceとlocal-key Providerをinvalidateする | `lib/controller/device.dart` |
| [GF-02044](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/device.dart#L119) | Controller経由で所有証明を実行する | `lib/controller/device.dart` |
| [GF-02045](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/device.dart#L123) | 所有証明後にattestationとdevice Providerをinvalidateする | `lib/controller/device.dart` |
| [GF-02046](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/device.dart#L137) | deviceを失効し、ローカル鍵のcleanupを開始する | `lib/controller/device.dart` |
| [GF-02047](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/device.dart#L141) | 失効deviceの情報を返すProviderをinvalidateする | `lib/controller/device.dart` |
| [GF-02048](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/group.dart#L81) | Group usecase経由でgroupを作成する | `lib/controller/group.dart` |
| [GF-02049](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/group.dart#L85) | 作成後にgroup一覧を再取得する | `lib/controller/group.dart` |
| [GF-02050](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/group.dart#L97) | Group usecase経由でgroupの編集内容を保存する | `lib/controller/group.dart` |
| [GF-02051](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/group.dart#L101) | 編集後にgroup一覧を再取得する | `lib/controller/group.dart` |
| [GF-02052](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/group.dart#L109) | backend上のgroupを削除する | `lib/controller/group.dart` |
| [GF-02053](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/group.dart#L111) | 削除後にgroupとmembershipデータをinvalidateする | `lib/controller/group.dart` |
| [GF-02054](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/group.dart#L125) | backendのgroup membershipにdeviceを追加する | `lib/controller/group.dart` |
| [GF-02055](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/group.dart#L129) | 割り当て後にgroup membershipを再取得する | `lib/controller/group.dart` |
| [GF-02056](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/group.dart#L142) | backendのgroup membershipからdeviceを外す | `lib/controller/group.dart` |
| [GF-02057](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/group.dart#L146) | 割り当て解除後にgroup membershipを再取得する | `lib/controller/group.dart` |
| [GF-02058](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/role.dart#L131) | Gorapeにproject role bindingを作成する | `lib/controller/role.dart` |
| [GF-02059](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/role.dart#L133) | 作成後にproject role binding一覧を再取得する | `lib/controller/role.dart` |
| [GF-02060](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/role.dart#L140) | Gorapeからproject role bindingを削除する | `lib/controller/role.dart` |
| [GF-02061](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/role.dart#L144) | 削除後にproject role binding一覧を再取得する | `lib/controller/role.dart` |
| [GF-02062](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/role.dart#L155) | Gorapeにgroup role bindingを作成する | `lib/controller/role.dart` |
| [GF-02063](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/role.dart#L159) | 作成後にgroup role binding一覧を再取得する | `lib/controller/role.dart` |
| [GF-02064](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/role.dart#L174) | Gorapeからgroup role bindingを削除する | `lib/controller/role.dart` |
| [GF-02065](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/role.dart#L178) | 削除後にgroup role binding一覧を再取得する | `lib/controller/role.dart` |
| [GF-02066](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/connection.dart#L29) | platform既定値から接続設定の読み込みを始める | `lib/usecase/connection.dart` |
| [GF-02067](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/connection.dart#L31) | ローカル保存済みの接続設定を優先する | `lib/usecase/connection.dart` |
| [GF-02068](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/connection.dart#L36) | 必須OIDC scopeがない保存設定を拒否する | `lib/usecase/connection.dart` |
| [GF-02069](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/connection.dart#L46) | 接続URLとOIDC項目を検証する | `lib/usecase/connection.dart` |
| [GF-02070](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/connection.dart#L54) | 検証済み設定をsecure storageへ保存する | `lib/usecase/connection.dart` |
| [GF-02071](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/connection.dart#L61) | 保存overrideを削除しplatform既定値を返す | `lib/usecase/connection.dart` |
| [GF-02072](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/language.dart#L17) | 保存言語を復元し、未設定時は日本語にする | `lib/controller/language.dart` |
| [GF-02073](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/language.dart#L26) | 対応しているlocaleだけを受け付ける | `lib/controller/language.dart` |
| [GF-02074](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/language.dart#L30) | 言語を保存し、reactive UI stateを更新する | `lib/controller/language.dart` |
| [GF-02075](https://github.com/Gorapeflutter/gf-app/blob/main/lib/entity/model/role.dart#L157) | Keycloak user attributeを正規化する | `lib/entity/model/role.dart` |
| [GF-02076](https://github.com/Gorapeflutter/gf-app/blob/main/lib/entity/model/role.dart#L159) | token claimからrealm/client roleを集める | `lib/entity/model/role.dart` |
| [GF-02077](https://github.com/Gorapeflutter/gf-app/blob/main/lib/entity/model/role.dart#L173) | cluster roleとrole名のfallbackを解決する | `lib/entity/model/role.dart` |
| [GF-02078](https://github.com/Gorapeflutter/gf-app/blob/main/lib/entity/model/role.dart#L184) | claimとattributeからproject roleを構築する | `lib/entity/model/role.dart` |
| [GF-02079](https://github.com/Gorapeflutter/gf-app/blob/main/lib/entity/model/role.dart#L212) | claimとattributeからgroup roleを構築する | `lib/entity/model/role.dart` |
| [GF-02080](https://github.com/Gorapeflutter/gf-app/blob/main/lib/entity/model/role.dart#L241) | roleを含むgroup pathを解釈する | `lib/entity/model/role.dart` |
| [GF-02081](https://github.com/Gorapeflutter/gf-app/blob/main/lib/entity/model/role.dart#L275) | UI権限判定に使うrole snapshotを作成する | `lib/entity/model/role.dart` |
| [GF-02082](https://github.com/Gorapeflutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L62) | native method-channel操作を振り分ける | `android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt` |
| [GF-02083](https://github.com/Gorapeflutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L66) | 鍵生成前に登録challengeをdecodeする | `MainActivity.kt` |
| [GF-02084](https://github.com/Gorapeflutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L72) | 署名前に所有証明bytesをdecodeする | `MainActivity.kt` |
| [GF-02085](https://github.com/Gorapeflutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L88) | StrongBoxとhardware-backed Keystoreの対応を検出する | `MainActivity.kt` |
| [GF-02086](https://github.com/Gorapeflutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L92) | platform対応状況とsecurity levelを返す | `MainActivity.kt` |
| [GF-02087](https://github.com/Gorapeflutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L112) | 新規鍵生成前に古いaliasを削除する | `MainActivity.kt` |
| [GF-02088](https://github.com/Gorapeflutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L119) | StrongBoxを優先し、必要ならdevice TEEへfallbackする | `MainActivity.kt` |
| [GF-02089](https://github.com/Gorapeflutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L132) | Android Key Attestation certificate chainを要求する | `MainActivity.kt` |
| [GF-02090](https://github.com/Gorapeflutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L143) | 公開鍵、evidence chain、security levelをまとめる | `MainActivity.kt` |
| [GF-02091](https://github.com/Gorapeflutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L165) | signing purpose、digest、challengeを鍵に結び付ける | `MainActivity.kt` |
| [GF-02092](https://github.com/Gorapeflutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L179) | Android Keystore内でkey pairを生成する | `MainActivity.kt` |
| [GF-02093](https://github.com/Gorapeflutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L190) | Keystore aliasでprivate-key entryを読み込む | `MainActivity.kt` |
| [GF-02094](https://github.com/Gorapeflutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L196) | SHA256withECDSAでchallengeの生bytesに署名する | `MainActivity.kt` |
| [GF-02095](https://github.com/Gorapeflutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L200) | DER署名をpaddingなしBase64urlで返す | `MainActivity.kt` |
| [GF-02096](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L311) | 登録フォームのerrorを消し処理中stateにする | `lib/ui/screens/register_device_screen.dart` |
| [GF-02097](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L319) | 端末登録application flowを呼び出す | `lib/ui/screens/register_device_screen.dart` |
| [GF-02098](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L327) | 検証済み端末の詳細と次の操作を表示する | `lib/ui/screens/register_device_screen.dart` |
| [GF-02099](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L365) | 親画面へ通知し、入力した端末名を消去する | `lib/ui/screens/register_device_screen.dart` |
| [GF-02100](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L369) | 登録失敗をフォーム上に表示する | `lib/ui/screens/register_device_screen.dart` |
| [GF-02101](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L376) | 成否にかかわらずフォームを待機stateへ戻す | `lib/ui/screens/register_device_screen.dart` |
| [GF-02102](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L314) | 所有証明errorを消して二重送信を防ぐ | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02103](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L322) | challenge署名による所有証明を実行する | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02104](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L330) | 成功を通知し端末のevidenceを再読み込みする | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02105](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L336) | 所有証明失敗を端末詳細画面に表示する | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02106](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L343) | 成否にかかわらず所有証明のlockを解除する | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02107](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L354) | 端末失効の前にユーザー確認を求める | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02108](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L382) | 端末失効の処理中stateにする | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02109](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L390) | backend端末を失効しローカル鍵をcleanupする | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02110](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L395) | 完了を通知し失効端末の詳細を閉じる | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02111](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L401) | 失効失敗時も現在の画面を維持する | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02112](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L408) | 成否にかかわらず失効処理のlockを解除する | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02113](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L386) | 表示中の結果を消し設定保存中stateにする | `lib/ui/screens/settings_screen.dart` |
| [GF-02114](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L395) | Controller経由で設定を検証・保存する | `lib/ui/screens/settings_screen.dart` |
| [GF-02115](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L398) | 設定保存の成功をユーザーに知らせる | `lib/ui/screens/settings_screen.dart` |
| [GF-02116](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L403) | 検証または保存errorを表示する | `lib/ui/screens/settings_screen.dart` |
| [GF-02117](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L410) | 成否にかかわらず保存中stateを解除する | `lib/ui/screens/settings_screen.dart` |
| [GF-02118](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L421) | reset中stateにし、設定操作の同時実行を防ぐ | `lib/ui/screens/settings_screen.dart` |
| [GF-02119](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L430) | 保存overrideを削除してplatform既定値を読み込む | `lib/ui/screens/settings_screen.dart` |
| [GF-02120](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L434) | 入力欄をreset後の設定値に同期する | `lib/ui/screens/settings_screen.dart` |
| [GF-02121](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L441) | 既定値へのreset完了を知らせる | `lib/ui/screens/settings_screen.dart` |
| [GF-02122](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L446) | フォームを維持したままreset errorを表示する | `lib/ui/screens/settings_screen.dart` |
| [GF-02123](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L453) | reset後の保存中stateを解除する | `lib/ui/screens/settings_screen.dart` |
| [GF-02124](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L464) | 古い結果を消してhealth checkを開始する | `lib/ui/screens/settings_screen.dart` |
| [GF-02125](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L473) | 設定済みGorape endpointへhealth requestを送る | `lib/ui/screens/settings_screen.dart` |
| [GF-02126](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L476) | health responseを整形して表示する | `lib/ui/screens/settings_screen.dart` |
| [GF-02127](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L485) | health checkの通信/API errorを表示する | `lib/ui/screens/settings_screen.dart` |
| [GF-02128](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L492) | health checkの進行中stateを解除する | `lib/ui/screens/settings_screen.dart` |
| [GF-02129](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L365) | group編集内容を集めdialog取消を処理する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02130](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L373) | Group Controller経由で変更を保存する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02131](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L382) | 画面内group stateを更新し成功を表示する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02132](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L401) | 取り消せないgroup削除を確認する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02133](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L431) | Group Controller経由でgroupを削除する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02134](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L436) | 削除成功後にgroup詳細画面を閉じる | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02135](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L451) | 未割り当てのactive deviceを探す | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02136](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L472) | 割り当て可能なdeviceをユーザーに選ばせる | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02137](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L480) | 選択deviceをbackend group membershipに追加する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02138](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L498) | group membership解除の処理中stateにする | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02139](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L504) | backend group membershipからdeviceを外す | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02140](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L522) | 付与するsubjectとroleを入力する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02141](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L530) | Controller経由でgroup role bindingを保存する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02142](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L555) | group role binding削除の処理中stateにする | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02143](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L561) | 指定したgroup role bindingを削除する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02144](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L356) | group情報を入力しdialog取消を処理する | `lib/ui/screens/project_management_screen.dart` |
| [GF-02145](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L364) | groupを作成し結果をproject管理画面に表示する | `lib/ui/screens/project_management_screen.dart` |
| [GF-02146](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L387) | 付与するsubjectとproject roleを入力する | `lib/ui/screens/project_management_screen.dart` |
| [GF-02147](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L395) | Controller経由でproject role bindingを保存する | `lib/ui/screens/project_management_screen.dart` |
| [GF-02148](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L419) | project role binding削除の処理中stateにする | `lib/ui/screens/project_management_screen.dart` |
| [GF-02149](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L425) | 指定したproject role bindingを削除する | `lib/ui/screens/project_management_screen.dart` |
| [GF-02150](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L443) | 取り消せない端末失効を確認する | `lib/ui/screens/project_management_screen.dart` |
| [GF-02151](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L473) | 端末を失効しローカル鍵情報をcleanupする | `lib/ui/screens/project_management_screen.dart` |
| [GF-02152](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_management_screen.dart#L130) | group情報を入力しdialog取消を処理する | `lib/ui/screens/group_management_screen.dart` |
| [GF-02153](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_management_screen.dart#L138) | groupを作成しserver生成recordを受け取る | `lib/ui/screens/group_management_screen.dart` |
| [GF-02154](https://github.com/Gorapeflutter/gf-app/blob/main/lib/ui/screens/group_management_screen.dart#L146) | 作成完了を知らせ、新しいgroup詳細を開く | `lib/ui/screens/group_management_screen.dart` |
| [GF-02155](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/auth.dart#L75) | sign-in前にloading stateへ切り替える | `lib/controller/auth.dart` |
| [GF-02156](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/auth.dart#L78) | sign-in usecaseを呼びsessionをstateへ反映する | `lib/controller/auth.dart` |
| [GF-02157](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/auth.dart#L83) | 想定内の認証errorをUI向けstateとして保持する | `lib/controller/auth.dart` |
| [GF-02158](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/auth.dart#L86) | 想定外errorを認証失敗として包む | `lib/controller/auth.dart` |
| [GF-02159](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/auth.dart#L97) | 実行中refreshを再利用し重複requestを防ぐ | `lib/controller/auth.dart` |
| [GF-02160](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/auth.dart#L100) | refreshを一度開始し、終了時に進行中markerを消す | `lib/controller/auth.dart` |
| [GF-02161](https://github.com/Gorapeflutter/gf-app/blob/main/lib/controller/auth.dart#L138) | 拒否されたcredentialを消してから認証errorを通知する | `lib/controller/auth.dart` |
| [GF-02162](https://github.com/Gorapeflutter/gf-app/blob/main/lib/repository/gorape.dart#L657) | validation errorにattestationの確認事項を付ける | `lib/repository/gorape.dart` |
| [GF-02163](https://github.com/Gorapeflutter/gf-app/blob/main/lib/repository/gorape.dart#L666) | forbidden操作にbackend role認可の説明を付ける | `lib/repository/gorape.dart` |
| [GF-02164](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L269) | backend verifierがimplementedの場合だけ続行する | `lib/usecase/device.dart` |
| [GF-02165](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L293) | challengeをdecodeし、空bytesを拒否する | `lib/usecase/device.dart` |
| [GF-02166](https://github.com/Gorapeflutter/gf-app/blob/main/lib/usecase/device.dart#L298) | 不正challengeをdomain errorへ変換する | `lib/usecase/device.dart` |
