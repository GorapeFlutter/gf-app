# 関数内処理ステップID一覧

[GF-02000](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L53)以降は、複数段階の関数に含まれる主要な処理ステップを示します。個々の文ではなく、意味のある処理境界に付けたIDです。ソースコード中の英語コメントと照合できます。

| ID | 処理ステップ | ソース |
| --- | --- | --- |
| [GF-02000](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L53) | Secure Storageに保存されたtokenを読み、decodeする | `lib/back/usecase/auth.dart` |
| [GF-02001](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L60) | 不正なsessionデータを削除する | `lib/back/usecase/auth.dart` |
| [GF-02002](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L64) | 有効なaccess tokenを持つsessionを再利用する | `lib/back/usecase/auth.dart` |
| [GF-02003](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L68) | 期限切れsessionをrefreshし、新しいtokenを保存する | `lib/back/usecase/auth.dart` |
| [GF-02004](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L76) | refreshできない期限切れsessionを削除する | `lib/back/usecase/auth.dart` |
| [GF-02005](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L87) | OIDC非対応platformでのsign-inを拒否する | `lib/back/usecase/auth.dart` |
| [GF-02006](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L93) | Authorization Code + PKCEでsign-inする | `lib/back/usecase/auth.dart` |
| [GF-02007](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L105) | 認証済みsessionを返す前にtokenを保存する | `lib/back/usecase/auth.dart` |
| [GF-02008](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L123) | adapterまたはrefresh tokenがない場合に更新を省略する | `lib/back/usecase/auth.dart` |
| [GF-02009](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L126) | tokenをrefreshし、新しいtokenを保存する | `lib/back/usecase/auth.dart` |
| [GF-02010](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L139) | 対応platformのremote sessionをproviderからsign-outする | `lib/back/usecase/auth.dart` |
| [GF-02011](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L149) | remote sign-out後にローカルsessionを削除する | `lib/back/usecase/auth.dart` |
| [GF-02012](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L621) | API URI、JSON body、request headerを組み立てる | `lib/back/repository/gorape.dart` |
| [GF-02013](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L636) | 最初のAPI requestを送信する | `lib/back/repository/gorape.dart` |
| [GF-02014](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L646) | 期限切れaccess tokenのrefreshを一度だけ試す | `lib/back/repository/gorape.dart` |
| [GF-02015](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L654) | 新しいtokenで元のAPI requestを一度だけ再試行する | `lib/back/repository/gorape.dart` |
| [GF-02016](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L664) | 成功したJSON responseをdecodeする | `lib/back/repository/gorape.dart` |
| [GF-02017](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L672) | HTTP errorをアプリケーション例外へ変換する | `lib/back/repository/gorape.dart` |
| [GF-02018](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L704) | HTTP methodに応じてrequestを振り分ける | `lib/back/repository/gorape.dart` |
| [GF-02019](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L740) | request timeoutをnetwork errorへ変換する | `lib/back/repository/gorape.dart` |
| [GF-02020](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L756) | HTTP clientの接続失敗をnetwork errorへ変換する | `lib/back/repository/gorape.dart` |
| [GF-02021](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L770) | JSONから構造化されたAPI error情報を読む | `lib/back/repository/gorape.dart` |
| [GF-02022](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L781) | 認証拒否errorに確認事項を付加する | `lib/back/repository/gorape.dart` |
| [GF-02023](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L96) | 登録名を正規化し、入力を検証する | `lib/back/usecase/device.dart` |
| [GF-02024](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L106) | 端末側のOS鍵・attestation対応状況を確認する | `lib/back/usecase/device.dart` |
| [GF-02025](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L119) | backend verifierが設定済みであることを確認する | `lib/back/usecase/device.dart` |
| [GF-02026](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L122) | 一度だけ使える登録challengeを要求する | `lib/back/usecase/device.dart` |
| [GF-02027](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L134) | decodeしたchallengeを新しいOS鍵に結び付ける | `lib/back/usecase/device.dart` |
| [GF-02028](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L151) | 公開鍵とattestation evidenceを送信する | `lib/back/usecase/device.dart` |
| [GF-02029](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L174) | server検証成功後にローカルkey aliasを保存する | `lib/back/usecase/device.dart` |
| [GF-02030](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L182) | 登録失敗時に生成した鍵を削除する | `lib/back/usecase/device.dart` |
| [GF-02031](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L199) | 登録済みローカル秘密鍵を読み、利用可能か確認する | `lib/back/usecase/device.dart` |
| [GF-02032](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L213) | 新しい所有証明challengeを要求する | `lib/back/usecase/device.dart` |
| [GF-02033](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L223) | OS key store内でchallengeの生bytesに署名する | `lib/back/usecase/device.dart` |
| [GF-02034](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L234) | 署名をserver検証へ送信する | `lib/back/usecase/device.dart` |
| [GF-02035](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L253) | backendの正本であるdevice recordを失効する | `lib/back/usecase/device.dart` |
| [GF-02036](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L257) | ローカル鍵とmetadataをbest-effortで削除する | `lib/back/usecase/device.dart` |
| [GF-02037](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L47) | platform、設定、認証stateを読み解く | `lib/app.dart` |
| [GF-02038](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L53) | 設定読み込み中にsplash screenを表示する | `lib/app.dart` |
| [GF-02039](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L57) | retry操作を付けて接続設定errorを表示する | `lib/app.dart` |
| [GF-02040](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L78) | 認証済みsessionをapp shellへ遷移させる | `lib/app.dart` |
| [GF-02041](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L89) | platformと設定を渡してlogin screenを構築する | `lib/app.dart` |
| [GF-02042](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L109) | Controller経由で端末登録usecaseを実行する | `lib/back/controller/device.dart` |
| [GF-02043](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L113) | 登録後にdeviceとlocal-key Providerをinvalidateする | `lib/back/controller/device.dart` |
| [GF-02044](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L147) | Controller経由で所有証明を実行する | `lib/back/controller/device.dart` |
| [GF-02045](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L151) | 所有証明後にattestationとdevice Providerをinvalidateする | `lib/back/controller/device.dart` |
| [GF-02046](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L178) | deviceを失効し、ローカル鍵のcleanupを開始する | `lib/back/controller/device.dart` |
| [GF-02047](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L182) | 失効deviceの情報を返すProviderをinvalidateする | `lib/back/controller/device.dart` |
| [GF-02048](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L81) | Group usecase経由でgroupを作成する | `lib/back/controller/group.dart` |
| [GF-02049](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L85) | 作成後にgroup一覧を再取得する | `lib/back/controller/group.dart` |
| [GF-02050](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L97) | Group usecase経由でgroupの編集内容を保存する | `lib/back/controller/group.dart` |
| [GF-02051](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L101) | 編集後にgroup一覧を再取得する | `lib/back/controller/group.dart` |
| [GF-02052](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L109) | backend上のgroupを削除する | `lib/back/controller/group.dart` |
| [GF-02053](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L111) | 削除後にgroupとmembershipデータをinvalidateする | `lib/back/controller/group.dart` |
| [GF-02054](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L125) | backendのgroup membershipにdeviceを追加する | `lib/back/controller/group.dart` |
| [GF-02055](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L129) | 割り当て後にgroup membershipを再取得する | `lib/back/controller/group.dart` |
| [GF-02056](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L142) | backendのgroup membershipからdeviceを外す | `lib/back/controller/group.dart` |
| [GF-02057](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L146) | 割り当て解除後にgroup membershipを再取得する | `lib/back/controller/group.dart` |
| [GF-02058](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L131) | Gorapeにproject role bindingを作成する | `lib/back/controller/role.dart` |
| [GF-02059](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L133) | 作成後にproject role binding一覧を再取得する | `lib/back/controller/role.dart` |
| [GF-02060](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L140) | Gorapeからproject role bindingを削除する | `lib/back/controller/role.dart` |
| [GF-02061](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L144) | 削除後にproject role binding一覧を再取得する | `lib/back/controller/role.dart` |
| [GF-02062](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L155) | Gorapeにgroup role bindingを作成する | `lib/back/controller/role.dart` |
| [GF-02063](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L159) | 作成後にgroup role binding一覧を再取得する | `lib/back/controller/role.dart` |
| [GF-02064](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L174) | Gorapeからgroup role bindingを削除する | `lib/back/controller/role.dart` |
| [GF-02065](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L178) | 削除後にgroup role binding一覧を再取得する | `lib/back/controller/role.dart` |
| [GF-02066](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L29) | platform既定値から接続設定の読み込みを始める | `lib/back/usecase/connection.dart` |
| [GF-02067](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L31) | ローカル保存済みの接続設定を優先する | `lib/back/usecase/connection.dart` |
| [GF-02068](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L36) | 必須OIDC scopeがない保存設定を拒否する | `lib/back/usecase/connection.dart` |
| [GF-02069](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L61) | 接続URLとOIDC項目を検証する | `lib/back/usecase/connection.dart` |
| [GF-02070](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L69) | 検証済み設定をsecure storageへ保存する | `lib/back/usecase/connection.dart` |
| [GF-02071](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L76) | 保存overrideを削除しplatform既定値を返す | `lib/back/usecase/connection.dart` |
| [GF-02072](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/language.dart#L17) | 保存言語を復元し、未設定時は日本語にする | `lib/back/controller/language.dart` |
| [GF-02073](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/language.dart#L26) | 対応しているlocaleだけを受け付ける | `lib/back/controller/language.dart` |
| [GF-02074](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/language.dart#L30) | 言語を保存し、reactive UI stateを更新する | `lib/back/controller/language.dart` |
| [GF-02075](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L157) | Keycloak user attributeを正規化する | `lib/entity/model/role.dart` |
| [GF-02076](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L159) | token claimからrealm/client roleを集める | `lib/entity/model/role.dart` |
| [GF-02077](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L173) | cluster roleとrole名のfallbackを解決する | `lib/entity/model/role.dart` |
| [GF-02078](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L184) | claimとattributeからproject roleを構築する | `lib/entity/model/role.dart` |
| [GF-02079](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L212) | claimとattributeからgroup roleを構築する | `lib/entity/model/role.dart` |
| [GF-02080](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L241) | roleを含むgroup pathを解釈する | `lib/entity/model/role.dart` |
| [GF-02081](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L275) | UI権限判定に使うrole snapshotを作成する | `lib/entity/model/role.dart` |
| [GF-02082](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L67) | native method-channel操作を振り分ける | `android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt` |
| [GF-02083](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L71) | 鍵生成前に登録challengeをdecodeする | `MainActivity.kt` |
| [GF-02084](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L77) | 署名前に所有証明bytesをdecodeする | `MainActivity.kt` |
| [GF-02085](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L93) | StrongBoxとhardware-backed Keystoreの対応を検出する | `MainActivity.kt` |
| [GF-02086](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L97) | platform対応状況とsecurity levelを返す | `MainActivity.kt` |
| [GF-02087](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L117) | 新規鍵生成前に古いaliasを削除する | `MainActivity.kt` |
| [GF-02088](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L124) | StrongBoxを優先し、必要ならdevice TEEへfallbackする | `MainActivity.kt` |
| [GF-02089](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L137) | Android Key Attestation certificate chainを要求する | `MainActivity.kt` |
| [GF-02090](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L162) | 公開鍵、evidence chain、security levelをまとめる | `MainActivity.kt` |
| [GF-02091](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L182) | signing purpose、digest、challengeを鍵に結び付ける | `MainActivity.kt` |
| [GF-02092](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L196) | Android Keystore内でkey pairを生成する | `MainActivity.kt` |
| [GF-02093](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L207) | Keystore aliasでprivate-key entryを読み込む | `MainActivity.kt` |
| [GF-02094](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L213) | SHA256withECDSAでchallengeの生bytesに署名する | `MainActivity.kt` |
| [GF-02095](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L217) | DER署名をpaddingなしBase64urlで返す | `MainActivity.kt` |
| [GF-02096](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L206) | 登録フォームのerrorを消し処理中stateにする | `lib/ui/screens/register_device_screen.dart` |
| [GF-02097](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L214) | 端末登録application flowを呼び出す | `lib/ui/screens/register_device_screen.dart` |
| [GF-02098](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L222) | 検証済み端末の詳細と次の操作を表示する | `lib/ui/screens/register_device_screen.dart` |
| [GF-02099](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L264) | 親画面へ通知し、入力した端末名を消去する | `lib/ui/screens/register_device_screen.dart` |
| [GF-02100](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L268) | 登録失敗をフォーム上に表示する | `lib/ui/screens/register_device_screen.dart` |
| [GF-02101](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L276) | 成否にかかわらずフォームを待機stateへ戻す | `lib/ui/screens/register_device_screen.dart` |
| [GF-02102](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L301) | 所有証明errorを消して二重送信を防ぐ | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02103](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L309) | challenge署名による所有証明を実行する | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02104](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L317) | 成功を通知し端末のevidenceを再読み込みする | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02105](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L323) | 所有証明失敗を端末詳細画面に表示する | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02106](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L331) | 成否にかかわらず所有証明のlockを解除する | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02107](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L343) | 端末失効の前にユーザー確認を求める | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02108](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L368) | 端末失効の処理中stateにする | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02109](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L376) | backend端末を失効しローカル鍵をcleanupする | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02110](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L381) | 完了を通知し失効端末の詳細を閉じる | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02111](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L387) | 失効失敗時も現在の画面を維持する | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02112](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L395) | 成否にかかわらず失効処理のlockを解除する | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02113](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L385) | 表示中の結果を消し設定保存中stateにする | `lib/ui/screens/settings_screen.dart` |
| [GF-02114](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L394) | Controller経由で設定を検証・保存する | `lib/ui/screens/settings_screen.dart` |
| [GF-02115](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L397) | 設定保存の成功をユーザーに知らせる | `lib/ui/screens/settings_screen.dart` |
| [GF-02116](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L402) | 検証または保存errorを表示する | `lib/ui/screens/settings_screen.dart` |
| [GF-02117](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L409) | 成否にかかわらず保存中stateを解除する | `lib/ui/screens/settings_screen.dart` |
| [GF-02118](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L420) | reset中stateにし、設定操作の同時実行を防ぐ | `lib/ui/screens/settings_screen.dart` |
| [GF-02119](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L429) | 保存overrideを削除してplatform既定値を読み込む | `lib/ui/screens/settings_screen.dart` |
| [GF-02120](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L433) | 入力欄をreset後の設定値に同期する | `lib/ui/screens/settings_screen.dart` |
| [GF-02121](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L440) | 既定値へのreset完了を知らせる | `lib/ui/screens/settings_screen.dart` |
| [GF-02122](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L445) | フォームを維持したままreset errorを表示する | `lib/ui/screens/settings_screen.dart` |
| [GF-02123](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L452) | reset後の保存中stateを解除する | `lib/ui/screens/settings_screen.dart` |
| [GF-02124](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L463) | 古い結果を消してhealth checkを開始する | `lib/ui/screens/settings_screen.dart` |
| [GF-02125](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L472) | 設定済みGorape endpointへhealth requestを送る | `lib/ui/screens/settings_screen.dart` |
| [GF-02126](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L475) | health responseを整形して表示する | `lib/ui/screens/settings_screen.dart` |
| [GF-02127](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L484) | health checkの通信/API errorを表示する | `lib/ui/screens/settings_screen.dart` |
| [GF-02128](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L491) | health checkの進行中stateを解除する | `lib/ui/screens/settings_screen.dart` |
| [GF-02129](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L361) | group編集内容を集めdialog取消を処理する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02130](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L369) | Group Controller経由で変更を保存する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02131](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L378) | 画面内group stateを更新し成功を表示する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02132](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L397) | 取り消せないgroup削除を確認する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02133](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L427) | Group Controller経由でgroupを削除する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02134](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L432) | 削除成功後にgroup詳細画面を閉じる | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02135](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L447) | 未割り当てのactive deviceを探す | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02136](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L468) | 割り当て可能なdeviceをユーザーに選ばせる | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02137](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L476) | 選択deviceをbackend group membershipに追加する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02138](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L494) | group membership解除の処理中stateにする | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02139](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L500) | backend group membershipからdeviceを外す | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02140](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L518) | 付与するsubjectとroleを入力する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02141](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L526) | Controller経由でgroup role bindingを保存する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02142](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L551) | group role binding削除の処理中stateにする | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02143](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L557) | 指定したgroup role bindingを削除する | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02144](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L355) | group情報を入力しdialog取消を処理する | `lib/ui/screens/project_management_screen.dart` |
| [GF-02145](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L363) | groupを作成し結果をproject管理画面に表示する | `lib/ui/screens/project_management_screen.dart` |
| [GF-02146](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L386) | 付与するsubjectとproject roleを入力する | `lib/ui/screens/project_management_screen.dart` |
| [GF-02147](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L394) | Controller経由でproject role bindingを保存する | `lib/ui/screens/project_management_screen.dart` |
| [GF-02148](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L418) | project role binding削除の処理中stateにする | `lib/ui/screens/project_management_screen.dart` |
| [GF-02149](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L424) | 指定したproject role bindingを削除する | `lib/ui/screens/project_management_screen.dart` |
| [GF-02150](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L442) | 取り消せない端末失効を確認する | `lib/ui/screens/project_management_screen.dart` |
| [GF-02151](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L472) | 端末を失効しローカル鍵情報をcleanupする | `lib/ui/screens/project_management_screen.dart` |
| [GF-02152](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_management_screen.dart#L128) | group情報を入力しdialog取消を処理する | `lib/ui/screens/group_management_screen.dart` |
| [GF-02153](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_management_screen.dart#L136) | groupを作成しserver生成recordを受け取る | `lib/ui/screens/group_management_screen.dart` |
| [GF-02154](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_management_screen.dart#L144) | 作成完了を知らせ、新しいgroup詳細を開く | `lib/ui/screens/group_management_screen.dart` |
| [GF-02155](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L103) | sign-in前にloading stateへ切り替える | `lib/back/controller/auth.dart` |
| [GF-02156](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L112) | sign-in usecaseを呼びsessionをstateへ反映する | `lib/back/controller/auth.dart` |
| [GF-02157](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L122) | 想定内の認証errorをUI向けstateとして保持する | `lib/back/controller/auth.dart` |
| [GF-02158](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L140) | 想定外errorを認証失敗として包む | `lib/back/controller/auth.dart` |
| [GF-02159](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L175) | 実行中refreshを再利用し重複requestを防ぐ | `lib/back/controller/auth.dart` |
| [GF-02160](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L178) | refreshを一度開始し、終了時に進行中markerを消す | `lib/back/controller/auth.dart` |
| [GF-02161](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L244) | 拒否されたcredentialを消してから認証errorを通知する | `lib/back/controller/auth.dart` |
| [GF-02162](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L791) | validation errorにattestationの確認事項を付ける | `lib/back/repository/gorape.dart` |
| [GF-02163](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L800) | forbidden操作にbackend role認可の説明を付ける | `lib/back/repository/gorape.dart` |
| [GF-02164](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L272) | backend verifierがimplementedの場合だけ続行する | `lib/back/usecase/device.dart` |
| [GF-02165](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L296) | challengeをdecodeし、空bytesを拒否する | `lib/back/usecase/device.dart` |
| [GF-02166](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L301) | 不正challengeをdomain errorへ変換する | `lib/back/usecase/device.dart` |
| [GF-02169](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L77) | credential情報を出さずにsession復元結果を記録する | `lib/back/controller/auth.dart` |
| [GF-02170](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L106) | tokenを出さずにsign-in方式と結果を記録する | `lib/back/controller/auth.dart` |
| [GF-02171](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L157) | Keycloak passkey actionの結果を記録する | `lib/back/controller/auth.dart` |
| [GF-02172](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L191) | token情報を出さずにrefresh結果を記録する | `lib/back/controller/auth.dart` |
| [GF-02173](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L701) | API method、ID除去済みpath、status、durationを記録する | `lib/back/repository/gorape.dart` |
| [GF-02174](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/passkey_device.dart#L56) | credential payloadを出さずに登録ceremony段階を記録する | `lib/back/usecase/passkey_device.dart` |
| [GF-02175](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/passkey_device.dart#L156) | assertion payloadを出さずに所有証明段階を記録する | `lib/back/usecase/passkey_device.dart` |
| [GF-02176](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L139) | AndroidのDevice Identity keyがsoftware-backedなら拒否する | `android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt` |
| [GF-02177](https://github.com/GorapeFlutter/gf-app/blob/main/platform/apple/SecureNativeKeyChannels.swift#L17) | Apple Secure EnclaveのDevice key channelを登録する | `platform/apple/SecureNativeKeyChannels.swift` |
| [GF-02178](https://github.com/GorapeFlutter/gf-app/blob/main/platform/apple/SecureNativeKeyChannels.swift#L102) | Secure EnclaveでP-256鍵を生成し非attested保証境界を返す | `platform/apple/SecureNativeKeyChannels.swift` |
| [GF-02179](https://github.com/GorapeFlutter/gf-app/blob/main/platform/apple/SecureNativeKeyChannels.swift#L185) | private materialをexportせずSecure Enclave鍵で署名する | `platform/apple/SecureNativeKeyChannels.swift` |
| [GF-02180](https://github.com/GorapeFlutter/gf-app/blob/main/windows/runner/windows_native_keys.cpp#L259) | Platform Crypto Providerでnon-exportable P-256鍵を作成する | `windows/runner/windows_native_keys.cpp` |
| [GF-02181](https://github.com/GorapeFlutter/gf-app/blob/main/windows/runner/windows_native_keys.cpp#L298) | TPM-backed CNG keyで署名する | `windows/runner/windows_native_keys.cpp` |
| [GF-02182](https://github.com/GorapeFlutter/gf-app/blob/main/windows/runner/windows_native_keys.cpp#L417) | Windows Device CNG/TPM channelを登録する | `windows/runner/windows_native_keys.cpp` |
| [GF-02183](https://github.com/GorapeFlutter/gf-app/blob/main/linux/runner/linux_native_keys.cc#L325) | TPM2 P-256鍵を生成しTPM-wrapped blobのみ保存する | `linux/runner/linux_native_keys.cc` |
| [GF-02184](https://github.com/GorapeFlutter/gf-app/blob/main/linux/runner/linux_native_keys.cc#L363) | TPM2 protected keyを再loadして署名する | `linux/runner/linux_native_keys.cc` |
| [GF-02185](https://github.com/GorapeFlutter/gf-app/blob/main/linux/runner/linux_native_keys.cc#L466) | Linux TPM2 Device channelを登録する | `linux/runner/linux_native_keys.cc` |
