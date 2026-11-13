import 'package:flutter/material.dart' as material;

/// Text widget that translates the app's Japanese source strings using the
/// locale selected in Settings. Dynamic server values and technical identifiers
/// are left untouched.
class AppText extends material.StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final String? data;
  final material.TextStyle? style;
  final material.StrutStyle? strutStyle;
  final material.TextAlign? textAlign;
  final material.TextDirection? textDirection;
  final material.Locale? locale;
  final bool? softWrap;
  final material.TextOverflow? overflow;
  final material.TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final material.TextWidthBasis? textWidthBasis;
  final material.TextHeightBehavior? textHeightBehavior;
  final material.Color? selectionColor;

  @override
  material.Widget build(material.BuildContext context) {
    return material.Text(
      AppStrings.translate(context, data),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

abstract final class AppStrings {
  static const _english = <String, String>{
    '設定エラー': 'Settings error',
    'ネットワークエラー': 'Network error',
    'リクエストが不正です': 'Invalid request',
    '認証が必要です': 'Authentication required',
    '権限がありません': 'Permission denied',
    '見つかりません': 'Not found',
    '検証に失敗しました': 'Validation failed',
    'サーバーエラー': 'Server error',
    'ログインエラー': 'Login error',
    'ログインがキャンセルされました。': 'Sign-in was cancelled.',
    'ログインをキャンセルしました': 'Sign-in cancelled',
    'このOSではログイン未対応です': 'Sign-in is not supported on this OS',
    'バックエンドが未対応です': 'Backend not supported',
    'デバイス鍵が見つかりません': 'Device key not found',
    'チャレンジが無効です': 'Invalid challenge',
    'ポリシーAPIは未提供です': 'Policy API is unavailable',
    '操作をキャンセルしました。': 'The operation was cancelled.',
    'キャンセルしました': 'Cancelled',
    'エラーが発生しました': 'An error occurred',
    'データ形式エラー': 'Data format error',
    'サーバーの応答を解釈できませんでした。': 'Could not read the server response.',
    '予期しないエラー': 'Unexpected error',
    '権限なし': 'No access',
    '閲覧者': 'Viewer',
    '編集者': 'Editor',
    '管理者': 'Administrator',
    'グループ作成・ロール付与・デバイス失効など、このスコープの管理操作をすべて実行できます。':
        'Can manage this scope, including groups, role assignments, and device revocation.',
    'デバイスの登録・失効、グループへのデバイス割当を実行できます。グループ設定とロール付与は変更できません。':
        'Can register and revoke devices and assign devices to groups. Cannot manage groups or roles.',
    'デバイス、グループ、ロールを参照できます。変更操作は表示されません。':
        'Can view devices, groups, and roles. Editing actions are unavailable.',
    'このスコープのロールがKeycloakトークンに含まれていません。':
        'The Keycloak token has no role for this scope.',
    '参照': 'View',
    '編集操作': 'Edit',
    '管理操作': 'Manage',
    'アクセストークンへマッピングしてください。': 'Map these claims to the access token. ',
    '設定変更後は再ログインで反映されます。': 'Sign in again for changes to take effect.',
    '再試行': 'Retry',
    '読み込み中...': 'Loading…',
    '設定を読み込み中...': 'Loading settings…',
    'ログインしています...': 'Signing in…',
    'セッションを確認中...': 'Checking session…',
    '接続設定を読み込み中...': 'Loading connection settings…',
    'プロジェクトを読み込み中...': 'Loading projects…',
    'デバイスを読み込み中...': 'Loading devices…',
    'Verifier対応状況を取得中...': 'Loading verifier support…',
    'ポリシーを読み込み中...': 'Loading policy…',
    'GorapeFlutter': 'GorapeFlutter',
    '表示言語': 'Display language',
    '言語': 'Language',
    '日本語': 'Japanese',
    '設定': 'Settings',
    'デバイス': 'Devices',
    'デバイス登録': 'Register device',
    '登録': 'Register',
    '対応状況': 'Support',
    'ポリシー': 'Policy',
    '管理': 'Manage',
    'ログアウト': 'Sign out',
    '接続設定': 'Connection settings',
    '接続設定・Redirect URI': 'Connection settings / Redirect URI',
    'アカウント': 'Account',
    'アカウント登録': 'Create account',
    '閉じる': 'Close',
    '以下のURLをブラウザで開いてアカウントを登録してください。':
        'Open the following URL in a browser to create an account.',
    '管理者機能を使う場合は、管理者ロールを持つKeycloakアカウントでログインしてください。権限を切り替える場合は、ログアウトしてから再ログインしてください。':
        'To use admin features, sign in with a Keycloak account that has the admin role. Sign out before switching accounts.',
    'Keycloakでログイン': 'Sign in with Keycloak',
    '管理者ログイン': 'Admin sign in',
    'Keycloakへ接続中...': 'Connecting to Keycloak…',
    'Keycloakでサインインし、OS保護鍵をGorapeに登録します。パスキーとMFAはKeycloak、デバイス検証はGorapeが担当します。':
        'Sign in with Keycloak, then register an OS-protected key with Gorape. Keycloak handles passkeys and MFA; Gorape verifies devices.',
    'OS別の対応状況': 'Platform support',
    '対応': 'Supported',
    '未対応': 'Unsupported',
    '接続先': 'Endpoints',
    'Gorape API': 'Gorape API',
    'Keycloak / OIDC': 'Keycloak / OIDC',
    'API Base URL': 'API base URL',
    'OIDC Issuer': 'OIDC issuer',
    'Client ID': 'Client ID',
    'Redirect URI': 'Redirect URI',
    'Keycloak Redirect URI許可リスト': 'Keycloak redirect URI allowlist',
    'ヘルスチェック': 'Health check',
    'コピー': 'Copy',
    'Keycloakの gorape-client に以下を登録してください。既存CLI用の http://127.0.0.1:8400/callback は変更・削除しません。':
        'Add these URIs to the Keycloak gorape-client. The existing CLI callback will be preserved.',
    'ローカルKeycloakの例: admin CLIで clients/gorape-client の redirectUris に追加します。詳細は README を参照してください。':
        'For local Keycloak, add these to clients/gorape-client redirectUris using the admin CLI. See the README.',
    'HTTP接続はローカル開発専用です。本番ではHTTPSと正規のRedirect URIを使用してください。':
        'HTTP is for local development only. Use HTTPS and an approved redirect URI in production.',
    '保存': 'Save',
    '保存中...': 'Saving…',
    '初期値に戻す': 'Restore defaults',
    'セッション': 'Session',
    'ログイン前に接続先を確認できます。保存後に戻ってログインしてください。':
        'Check the endpoints before signing in. Save and return to sign in.',
    'ログアウトするとKeycloakのセッション終了を試行し、ローカルのトークンを削除します。':
        'Signing out attempts to end the Keycloak session and removes local tokens.',
    'Access TokenはGorape APIのBearer認証にのみ使用します。デバイス秘密鍵はOSキーストアから出ません。':
        'The access token is only used for Gorape API authentication. Device private keys stay in the OS keystore.',
    'Redirect URIをコピーしました。': 'Redirect URIs copied.',
    '接続設定を保存しました。': 'Connection settings saved.',
    '初期値に戻しました。': 'Defaults restored.',
    'HTTPの開発用接続です。本番ではHTTPSを使用してください。':
        'This is an HTTP development connection. Use HTTPS in production.',
    'Android Emulatorは 10.0.2.2、実機はPCのLAN IPを指定してください。adb reverse を使う場合は localhost:8000 も利用できます。':
        'Use 10.0.2.2 for Android emulators, your computer’s LAN IP for physical devices, or localhost:8000 with adb reverse.',
    'Android Emulatorでは OIDC 用に `adb reverse tcp:8080 tcp:8080` を実行してください。APIは既定で 10.0.2.2:8000 を利用します。':
        'For Android emulators, run `adb reverse tcp:8080 tcp:8080` for OIDC. The API defaults to 10.0.2.2:8000.',
    'Android端末を登録': 'Register Android device',
    'この端末': 'This device',
    'Gorapeバックエンド': 'Gorape backend',
    'Verifier対応状況を更新': 'Refresh verifier support',
    '登録情報': 'Registration details',
    '表示名': 'Display name',
    '例: Pixel 8 Pro': 'e.g. Pixel 8 Pro',
    'チャレンジを取得して登録': 'Get challenge and register',
    '登録しています...': 'Registering…',
    'このOSではOS保護鍵とAttestationが未実装のため登録できません。':
        'Registration is unavailable because protected keys and attestation are not implemented on this OS.',
    'デバイス登録にはプロジェクトのeditor以上のロールが必要です。':
        'Device registration requires the project editor role or higher.',
    '登録フローの詳細': 'Registration flow details',
    'デバイスを登録しました': 'Device registered',
    'バックエンドがAttestationをverifiedとして記録しました。続けてチャレンジ署名による所有証明を実行できます。':
        'The backend recorded the attestation as verified. You can now prove key possession by signing a challenge.',
    '一覧へ': 'Back to list',
    'デバイス一覧を開く': 'Open device list',
    '登録済みデバイス': 'Registered devices',
    '閲覧者のためデバイスを登録できません。管理者または編集者のロールが必要です。':
        'Viewers cannot register devices. An administrator or editor role is required.',
    'このスコープではデバイスを登録できません。管理者または編集者のロールが必要です。':
        'You cannot register devices in this scope. An administrator or editor role is required.',
    '参照はGorape側の権限に従いますが、登録・失効などの変更操作は無効です。閲覧者のため、デバイスの登録・失効は実行できません。':
        'Viewing follows Gorape permissions, but changes are disabled for viewers.',
    '閲覧者のため、デバイスの登録・失効は実行できません。': 'Viewers cannot register or revoke devices.',
    'Android実機でOS保護鍵を生成し、Gorapeへ登録してください。登録後、チャレンジ署名による所有証明を実行できます。':
        'Generate a protected key on an Android device and register it with Gorape. Then prove possession by signing a challenge.',
    'デバイスが登録されていません': 'No devices registered',
    'デバイスが登録されていません。': 'No devices are registered.',
    'この端末の鍵': 'Key on this device',
    'デバイス詳細': 'Device details',
    '再読み込み': 'Refresh',
    'デバイス操作': 'Device actions',
    '参照はできますが、所有証明・失効は実行できません。閲覧者のため、所有証明とデバイス失効は実行できません。':
        'View access is available, but proof and revocation are disabled for viewers.',
    '閲覧者のため、所有証明とデバイス失効は実行できません。':
        'Viewers cannot prove possession or revoke devices.',
    'デバイス状態': 'Device status',
    'デバイスID': 'Device ID',
    'プラットフォーム': 'Platform',
    '登録日時': 'Registered',
    '最終検証': 'Last verified',
    '失効日時': 'Revoked',
    'バージョン': 'Version',
    'この端末には該当デバイスの秘密鍵がありません。\n他端末で登録されたデバイスは表示・失効のみ可能です。':
        'The private key for this device is not on this device. Devices registered elsewhere can only be viewed or revoked.',
    'ローカル登録': 'Registered locally',
    '操作': 'Actions',
    'チャレンジ署名で所有証明': 'Prove possession by signing a challenge',
    'デバイスを失効': 'Revoke device',
    '所有証明ではBase64urlチャレンジを生バイト列に戻し、OS鍵で署名します。ECDSAはASN.1 DER、RSAはPKCS#1 v1.5/SHA-256、Ed25519は生バイト列です。':
        'The Base64url challenge is decoded and signed with the OS key. ECDSA uses ASN.1 DER; RSA uses PKCS#1 v1.5/SHA-256; Ed25519 uses raw bytes.',
    '最新の記録を取得': 'Refresh records',
    'Attestation記録': 'Attestation records',
    'Attestation記録はありません。': 'No attestation records.',
    'チャレンジ署名をGorapeが検証しました。': 'Gorape verified the challenge signature.',
    'デバイスを失効しますか？': 'Revoke this device?',
    'この端末のローカル鍵も削除されます。元に戻せません。':
        'The local key on this device will also be deleted. This cannot be undone.',
    'キャンセル': 'Cancel',
    '失効する': 'Revoke',
    'デバイスを失効しました。': 'Device revoked.',
    'Android端末でOS保護鍵を生成し、Gorapeへ登録してください。':
        'Generate an OS-protected key on an Android device and register it with Gorape.',
    'チャレンジ署名の所有証明を実行できます。':
        'You can prove key possession by signing a challenge.',
    'デバイスポリシー（ローカルのみ）': 'Device policy (local only)',
    'この画面の値は端末内に保存される希望値です。Gorapeバックエンドでは強制されません。':
        'These preferences are stored on this device and are not enforced by the Gorape backend.',
    'バックエンドAPI未提供': 'Backend API unavailable',
    'ローカルポリシーを保存しました。': 'Local policy saved.',
    'ログインとデバイス鍵': 'Sign-in and device keys',
    'ログイン後の所有証明を推奨': 'Recommend proof of possession after sign-in',
    'Attestationなしのデバイスを許可': 'Allow devices without attestation',
    'バックエンドの登録APIはAttestation証拠を要求します。この設定は表示上の希望値であり、登録可否を変えません。':
        'The registration API requires attestation evidence. This preference is informational and does not change registration eligibility.',
    'パスキーとデバイス鍵': 'Passkeys and device keys',
    'デバイス専用鍵（推奨）': 'Device-bound key (recommended)',
    'Keycloakの共有パスキー': 'Shared Keycloak passkey',
    'パスキーはKeycloakアカウントに紐づき、複数端末で共有されます。このアプリはパスキー秘密情報を保存しません。':
        'Passkeys belong to the Keycloak account and can be shared across devices. This app never stores passkey secrets.',
    'パスキー・MFA・アカウント回復はKeycloakの責務です。このアプリはパスキー秘密情報を保存せず、Gorapeはデバイス公開鍵と所有証明を扱います。':
        'Keycloak handles passkeys, MFA, and account recovery. This app stores no passkey secrets; Gorape handles device public keys and proof of possession.',
    'この設定の扱い': 'About these settings',
    '現行のGorape OpenAPI 3.1にはデバイスポリシー設定APIがありません。この画面の設定は端末内の希望値であり、バックエンドで強制されません。デバイスポリシーAPIを追加してから接続してください。':
        'The current Gorape OpenAPI 3.1 has no device policy API. These are local preferences and are not enforced by the backend.',
    'バックエンド対応状況を更新': 'Refresh backend support',
    'Android Key Attestation': 'Android Key Attestation',
    'iOS / macOS': 'iOS / macOS',
    'Windows / Linux / Web': 'Windows / Linux / Web',
    '対応マトリクス': 'Support matrix',
    'ログイン': 'Sign-in',
    'OS鍵': 'OS key',
    'Attestation': 'Attestation',
    'Gorape': 'Gorape',
    'Keycloakログイン': 'Keycloak sign-in',
    'OS保護鍵の生成': 'Protected key generation',
    'Attestation（バックエンド）': 'Attestation (backend)',
    'Android Keystore + Key Attestation。バックエンドの信頼アンカー設定が必要です。':
        'Android Keystore + Key Attestation. Backend trust anchors must be configured.',
    'Keycloakログインのみ対応。AttestationはGorapeバックエンドがunsupportedを返します。':
        'Keycloak sign-in is supported. The Gorape backend reports attestation as unsupported.',
    'iOS/macOS/AndroidのみKeycloakログインを提供します。Windows向けflutter_appauth実装がありません。':
        'Keycloak sign-in is available on iOS, macOS, and Android. Windows has no flutter_appauth implementation.',
    'クラスタ': 'Cluster',
    'プロジェクト': 'Project',
    'グループ': 'Groups',
    'プロジェクトがありません': 'No project',
    '管理対象のプロジェクトがありません。クラスタ表示のみ利用できます。':
        'There are no projects to manage. Only the cluster view is available.',
    'クラスタ（Keycloak realm）': 'Cluster (Keycloak realm)',
    'クラスタのロールはKeycloakのrealm/clientロールから判定しています。':
        'Cluster roles are resolved from Keycloak realm and client roles.',
    'クラスタ情報は参照のみ表示されます。ロールやグループの変更は表示されません。':
        'Cluster information is read-only. Role and group changes are unavailable.',
    '管理者ビュー': 'Administrator view',
    'クラスタ全体のロール確認に加えて、各プロジェクトの管理画面へ移動できます。実際の作成・変更権限はGorapeのproject/groupロール付与に従います。':
        'Review cluster roles and open project management. Gorape project/group role bindings control actual permissions.',
    'サインイン情報': 'Sign-in information',
    'ユーザー名': 'Username',
    'メール': 'Email',
    'Keycloakロール': 'Keycloak roles',
    'realm_access/resource_accessにロールがありません。':
        'No roles in realm_access/resource_access.',
    'Keycloakグループ': 'Keycloak groups',
    'アクセストークンにgroupsクレームがありません。': 'The access token has no groups claim.',
    'プロジェクト別ロール': 'Project roles',
    '表示可能なプロジェクトがありません。': 'No projects are visible.',
    'Keycloak属性（gorape_*）': 'Keycloak attributes (gorape_*)',
    'ロール表示の切り替え方': 'How role views are selected',
    'ロールの確認方法': 'How to check roles',
    'ロールを変えると、この画面は管理者・編集者・閲覧者のいずれかに切り替わります。変更後は再ログイン（またはトークン更新）で反映されます。':
        'This view changes based on your administrator, editor, or viewer role. Sign in again or refresh the token after changing roles.',
    'Keycloakトークンのロール表示と、Gorape DBのproject/groupロール付与は別に管理されています。管理操作にはGorape側でadmin/editorの付与が必要です。':
        'Keycloak token roles and Gorape DB project/group bindings are managed separately. Management actions also require Gorape permissions.',
    'このIssuerのGorapeプロジェクトがbootstrap済みかも確認してください。':
        'Also verify that a Gorape project has been bootstrapped for this issuer.',
    'プロジェクト情報': 'Project information',
    'グループ一覧': 'Groups',
    'グループがありません。右上の「作成」から追加できます。': 'No groups yet. Use Create to add one.',
    'グループが作成されていません。': 'No groups have been created.',
    '各グループのロールは、プロジェクトロールとKeycloakのグループ別ロールの強い方で表示されます（Gorapeのeffective roleと同じ考え方）。':
        'Each group shows the stronger of its project role and Keycloak group role, matching Gorape effective-role resolution.',
    'プロジェクト、グループ、デバイスを参照できます。作成・変更・失効の操作は表示されません。':
        'Can view projects, groups, and devices. Create, update, and revoke actions are unavailable.',
    '編集者ビュー': 'Editor view',
    'デバイスの失効とグループへのデバイス割当が可能です。グループの作成・削除やロール付与は管理者のみ表示されます。':
        'Can revoke devices and assign devices to groups. Only administrators can manage groups and roles.',
    '名前': 'Name',
    'プロジェクトロール': 'Project roles',
    'グループロール': 'Group roles',
    '作成': 'Create',
    '付与': 'Assign',
    '失効': 'Revoke',
    '管理者: グループ作成・プロジェクト/グループのロール付与・デバイス失効が可能です。':
        'Admin: can create groups, assign project/group roles, and revoke devices.',
    '編集者: デバイス失効とグループへのデバイス割当が可能です。グループ作成とロール付与は管理者のみです。':
        'Editor: can revoke devices and assign them to groups. Only admins can create groups or assign roles.',
    '閲覧者: 参照のみ可能です。変更操作は表示されません。': 'Viewer: read-only access.',
    'このグループのロールがありません。': 'No role is assigned for this group.',
    'グループ情報': 'Group information',
    '作成日時': 'Created',
    '更新日時': 'Updated',
    'グループデバイス': 'Group devices',
    '追加': 'Add',
    'デバイスが割り当てられていません。': 'No devices are assigned.',
    'デバイスが割り当てられていません。右上の「追加」から割り当てできます。':
        'No devices are assigned. Use Add to assign one.',
    'グループから外す': 'Remove from group',
    'グループを編集': 'Edit group',
    'グループを削除': 'Delete group',
    'グループを削除しますか？': 'Delete this group?',
    'グループを作成': 'Create group',
    '小文字英数字とハイフン（例: engineering）':
        'Lowercase letters, numbers, and hyphens (e.g. engineering)',
    '表示名を入力してください。': 'Enter a display name.',
    'Slugは小文字英数字とハイフンで入力してください。':
        'Use lowercase letters, numbers, and hyphens for the slug.',
    '削除する': 'Delete',
    'グループを更新しました。': 'Group updated.',
    'グループロールを付与': 'Assign group role',
    '自分のロールは変更できません。最後のプロジェクト管理者も削除できません。':
        'You cannot change your own role or remove the last project administrator.',
    'OIDC Subjectを入力してください。': 'Enter the OIDC subject.',
    'OIDC Subject': 'OIDC subject',
    'Keycloakのsub（ユーザーのUUID）': 'Keycloak sub (user UUID)',
    'ロール': 'Role',
    'グループにデバイスを追加': 'Add device to group',
    '追加できるデバイスがありません。': 'No devices are available to add.',
    'グループロールがありません。': 'No group roles.',
    'プロジェクトロールがありません。': 'No project roles.',
    'グループロールを付与しました。': 'Group role assigned.',
    'グループロールを削除しました。': 'Group role removed.',
    'プロジェクトロールを付与しました。': 'Project role assigned.',
    'プロジェクトロールを削除しました。': 'Project role removed.',
    'グループを削除します。元に戻せません。': 'Delete this group? This cannot be undone.',
    'グループを作成しました。': 'Group created.',
    'デバイスをグループに追加しました。': 'Device added to group.',
    'デバイスをグループから外しました。': 'Device removed from group.',
    '追加できるデバイスがありません。デバイスタブで登録してください。':
        'No devices are available. Register a device first.',
    '閲覧者ビュー': 'Viewer view',
    '管理者: グループの編集・削除、デバイス割当、グループロール付与が可能です。':
        'Admin: can edit/delete groups, assign devices, and grant group roles.',
    '編集者: グループへのデバイス追加・削除が可能です。ロール付与は管理者のみです。':
        'Editor: can add/remove group devices. Only admins can assign roles.',
    '閲覧者: グループ内のデバイスを参照できます。': 'Viewer: can view devices in the group.',
    '対応状況を読み込み中...': 'Loading support status…',
    'Keycloak Realm': 'Keycloak realm',
    'Project ID': 'Project ID',
    'Slug': 'Slug',
    'Gorapeプロジェクトがありません': 'No Gorape project',
    'プロジェクトがまだ作成されていません。': 'No projects have been created yet.',
    'このプラットフォームではOIDCを利用できません。': 'OIDC is unavailable on this platform.',
    'ロールを付与': 'Assign role',
    'デバイス名を入力してください。': 'Enter a device name.',
    'このOSではOS保護鍵を生成できません。': 'Protected keys cannot be generated on this OS.',
    '登録チャレンジの有効期限が切れています。もう一度お試しください。':
        'The registration challenge expired. Please try again.',
    '署名チャレンジの有効期限が切れています。もう一度お試しください。':
        'The signing challenge expired. Please try again.',
    'この端末には該当デバイスの秘密鍵がありません。':
        'The private key for this device is not on this device.',
    '別の端末で登録されたデバイスは署名できません。この端末で登録し直してください。':
        'Devices registered on another device cannot sign here. Register this device again.',
    '端末の画面ロック設定とKeystoreの状態を確認してください。':
        'Check the screen-lock settings and Keystore status.',
    '端末のロック解除状態を確認するか、デバイスを再登録してください。':
        'Unlock the device or register it again.',
    'Keycloakからアクセストークンが返されませんでした。': 'Keycloak did not return an access token.',
    'ログインセッションがありません。もう一度ログインしてください。':
        'No sign-in session. Please sign in again.',
    'セッションを更新できません。もう一度ログインしてください。':
        'Could not refresh the session. Please sign in again.',
    'セッションの更新に失敗しました。もう一度ログインしてください。':
        'Session refresh failed. Please sign in again.',
    'Gorape APIへの接続がタイムアウトしました。': 'The connection to the Gorape API timed out.',
    'Gorape APIへ接続できませんでした。': 'Could not connect to the Gorape API.',
    'アクセストークンの有効期限、Issuer、Audience（gorape-api）を確認してください。初回起動時は、このIssuerのGorapeプロジェクトがbootstrap済みかも確認してください。':
        'Check the access token expiry, issuer, and audience (gorape-api). On first launch, ensure a Gorape project is bootstrapped for this issuer.',
    'アクセストークンの有効期限、Issuer、Audience（gorape-api）を確認してください。':
        'Check the access token expiry, issuer, and audience (gorape-api).',
    'Keycloakログインに失敗しました。': 'Keycloak sign-in failed.',
    'API URLとDocker環境を確認してください。': 'Check the API URL and Docker environment.',
    'OS保護鍵を利用できません': 'Protected key unavailable',
    'Attestationが未設定です': 'Attestation is not configured',
    '現行バックエンドではAndroid Key Attestationのみ実装されています。':
        'The current backend only implements Android Key Attestation.',
    'Android verifierは': 'The Android verifier is ',
    'GorapeのAndroid Attestation検証が未設定です。':
        'Android attestation verification is not configured in Gorape.',
    'バックエンドの android_trust_anchors が空の場合、capabilitiesは unconfiguredを返し、登録は422で失敗します。':
        'If backend android_trust_anchors is empty, capabilities reports unconfigured and registration fails with 422.',
    'Gorapeの Application.Server.Attestation.android_trust_anchors にGoogleのKey Attestation Root CAを設定し、capabilitiesが implementedを返すことを確認してください。':
        'Configure Google Key Attestation Root CA in Application.Server.Attestation.android_trust_anchors and verify capabilities reports implemented.',
    'Gorape APIへは送信されません（ポリシーAPIがないため）。':
        'Not sent to Gorape (no policy API is available).',
    'デバイスポリシーAPIを追加してから接続してください。': 'Add a device policy API before connecting.',
    '表示はKeycloakトークンのロールを反映し、API認可はGorape側でDBロール付与とKeycloakロールを用いて判定されます。':
        'The UI reflects Keycloak token roles; the API resolves authorization using Gorape role bindings and Keycloak roles.',
    '初回起動時は、このIssuerのGorapeプロジェクトがbootstrap済みかも確認してください。':
        'On first launch, verify that a Gorape project has been bootstrapped for this issuer.',
  };

  static const _englishFragments = <String, String>{
    'Android実機ではAndroid KeystoreにEC P-256鍵を生成し、':
        'On a physical Android device, generate an EC P-256 key in Android Keystore and ',
    'Attestation対象外です。Windows/Linux/Webでは':
        'Attestation is unavailable. On Windows/Linux/Web, ',
    'Base64urlを生バイト列へデコード': 'Decode Base64url into raw bytes',
    'EC P-256公開鍵と証明書チェーン（leaf-first）を送信':
        'Send the EC P-256 public key and certificate chain (leaf first)',
    'Gorapeに登録したOS保護鍵で所有証明を行います。':
        'Prove possession using the OS-protected key registered with Gorape.',
    'Gorapeのデバイス鍵による所有証明とは別物です。':
        'This is separate from proof of possession using a Gorape device key.',
    'Gorapeの実認可はDBロール付与とKeycloakクレームを併用して行われます。':
        'Gorape authorization combines database role bindings with Keycloak claims.',
    'GorapeはGoogle Hardware Attestation Root CAまでの':
        'Gorape verifies the chain up to the Google Hardware Attestation Root CA ',
    'Gorapeバックエンドでは強制されません。': 'is not enforced by the Gorape backend.',
    'Gorapeバックエンドのverifierが': 'the Gorape backend verifier ',
    'Gorapeリポジトリのgorape-adminでプロジェクトを':
        'Bootstrap a project with gorape-admin in the Gorape repository and ',
    'Gorape側でeditor権限があっても、UIからは登録できません。':
        'Registration is unavailable in the UI even if Gorape grants editor permissions.',
    'Gorape側でデバイスがrevokedになります。': 'The device will be revoked in Gorape.',
    'Key Attestation証明書チェーンをGorapeへ送信します。':
        'Send the Key Attestation certificate chain to Gorape.',
    'Key Attestation証明書チェーン（leaf-first）を取得します。':
        'Retrieve the Key Attestation certificate chain (leaf first).',
    'KeyGenParameterSpec.setAttestationChallenge に同じバイト列を設定':
        'Set the same bytes with KeyGenParameterSpec.setAttestationChallenge',
    'Keycloakでrealmロール admin が付与されています。':
        'The Keycloak realm role admin is assigned.',
    'Keycloakでサインインし、OS保護鍵をGorapeに登録します。':
        'Sign in with Keycloak and register an OS-protected key with Gorape.',
    'Keycloakでユーザーにrealmロール admin / editor / viewer を付与するか、':
        'Assign the user the Keycloak realm role admin/editor/viewer, or ',
    'Keycloakの gorape-client に以下を登録してください。':
        'Add the following to the Keycloak gorape-client.',
    'Keycloakのパスキーとは独立しています。': 'This is independent of Keycloak passkeys.',
    'KeycloakクライアントのGroup Membership mapperを有効にすると表示されます。':
        'Shown when the Group Membership mapper is enabled for the Keycloak client.',
    'Keycloakトークンにこのスコープのロールが含まれていません。':
        'The Keycloak token has no role for this scope.',
    'Keycloakトークンにこのプロジェクトのロールがありません。':
        'The Keycloak token has no role for this project.',
    'Keycloakトークンのロールから表示を切り替えています。':
        'The view is selected from roles in the Keycloak token.',
    'KeycloakユーザーがGorapeのProjectロールを持っていないか、':
        'The Keycloak user may not have a Gorape project role, or ',
    'Keycloakログインはflutter_appauthで対応します。':
        'Keycloak sign-in uses flutter_appauth.',
    'Keycloakログイン後にチャレンジ署名を促すUIを表示します。':
        'Show a prompt to sign a challenge after Keycloak sign-in.',
    'OIDC IssuerはKeycloakが発行する iss クレームと完全に一致する必要があります。':
        'The OIDC issuer must exactly match the iss claim issued by Keycloak.',
    'OS保護鍵で署名します。ECDSAはASN.1 DER、':
        'Sign with the OS-protected key. ECDSA uses ASN.1 DER; ',
    'POST /devices/registration/challenge で単一使用チャレンジを取得':
        'Request a single-use challenge with POST /devices/registration/challenge',
    'POST /devices/registration/verify が422なら信頼アンカーを確認':
        'If POST /devices/registration/verify returns 422, check the trust anchors',
    'RSAはPKCS#1 v1.5/SHA-256、Ed25519は生バイト列です。':
        'RSA uses PKCS#1 v1.5/SHA-256; Ed25519 signs raw bytes.',
    'Windows TPM、Linux、Webは現行のGorapeバックエンドで':
        'Windows TPM, Linux, and Web are ',
    'を実行してください。': ' run this command.',
    'adb reverse を使う場合は localhost:8000 も利用できます。':
        'With adb reverse, localhost:8000 can also be used.',
    'android_trust_anchors にGoogle Hardware Attestation Root CAを':
        'Add the Google Hardware Attestation Root CA to android_trust_anchors and ',
    'audience: gorape-api。Gorape APIにはAccess Tokenのみを使用し、':
        'audience: gorape-api. Only the access token is sent to the Gorape API; ',
    'flutter_appauthによるOIDCログインも未対応のため、':
        'OIDC sign-in with flutter_appauth is also unsupported, so ',
    'gorape_*属性がトークンに含まれていません。':
        'gorape_* attributes are not present in the token.',
    'gorape_project_role / gorape_group_<slug>_role 属性を':
        'Map the gorape_project_role / gorape_group_<slug>_role attributes ',
    'gorape_project_role / gorape_group_<slug>_role 属性をアクセストークンへマッピングしてください。':
        'Map gorape_project_role / gorape_group_<slug>_role attributes into the access token.',
    'iOS/macOS/AndroidのみKeycloakログインを提供します。':
        'Keycloak sign-in is available only on iOS/macOS/Android.',
    'realmロール admin / editor / viewer、または':
        'realm role admin/editor/viewer, or ',
    'redirectUris に追加します。詳細は README を参照してください。':
        'Add these to redirectUris. See the README for details.',
    'サーバーのチャレンジをKeyGenParameterSpecへバインドして':
        'Bind the server challenge to KeyGenParameterSpec and ',
    'サーバーのチャレンジをOS鍵生成にバインドし、公開鍵と':
        'Bind the server challenge to OS key generation and submit the public key and ',
    'チェーンを検証します。': 'Verify the certificate chain.',
    'デバイスの失効とグループへのデバイス割当が可能です。':
        'Can revoke devices and assign devices to groups.',
    'デバイス秘密鍵はOSキーストアから出ません。':
        'Device private keys never leave the OS keystore.',
    'バックエンドがAttestationをverifiedとして記録しました。':
        'The backend recorded the attestation as verified.',
    'バックエンドの android_trust_anchors が空の場合、':
        'If backend android_trust_anchors is empty, ',
    'バックエンドの登録APIはAttestation証拠を要求します。':
        'The backend registration API requires attestation evidence.',
    'バックエンド側のVerifier追加が必要です。': 'A backend verifier must be added.',
    'パスキーとMFAはKeycloak、デバイス検証はGorapeが担当します。':
        'Keycloak handles passkeys and MFA; Gorape handles device verification.',
    'パスキーとデバイス鍵の役割': 'How passkeys and device keys differ',
    'パスキーはKeycloakアカウントに紐づき、複数端末で共有されます。':
        'Passkeys belong to the Keycloak account and can be shared across devices.',
    'パスキー・MFA・アカウント回復はKeycloakの責務です。':
        'Keycloak handles passkeys, MFA, and account recovery.',
    'プロジェクト/グループ固有のロールはrealmロールへフォールバックします。':
        'Project/group-specific roles fall back to the realm role.',
    'プロジェクトのグループ': 'Project groups',
    'プロジェクトを切り替え': 'Switch project',
    'プロジェクト一覧': 'Project list',
    'ログアウトするとKeycloakのセッション終了を試行し、':
        'Signing out attempts to end the Keycloak session and ',
    'ログイン画面で明示的に案内します。': 'shown explicitly on the sign-in screen.',
    'ローカルのトークンを削除します。': 'removes local tokens.',
    'ロールを変えると、この画面は管理者・編集者・閲覧者のいずれかに切り替わります。':
        'Changing roles switches this screen between administrator, editor, and viewer views.',
    '他端末で登録されたデバイスは表示・失効のみ可能です。':
        'Devices registered on another device can only be viewed or revoked.',
    '参照はGorape側の権限に従いますが、登録・失効などの変更操作は無効です。':
        'Viewing follows Gorape permissions, but registration and revocation are disabled.',
    '参照はできますが、所有証明・失効は実行できません。':
        'Can view, but cannot prove possession or revoke devices.',
    '各グループのロールは、プロジェクトロールとKeycloakのグループ別ロールの':
        'Each group role is resolved from the project role and Keycloak group role; ',
    '有効ロールはプロジェクトロールとKeycloakのグループ別ロールから解決され、API側で再認可されます。':
        'The effective role combines project and Keycloak group roles; the API independently authorizes each request.',
    '実際の作成・変更権限はGorapeのproject/groupロール付与に従います。':
        'Actual create/update permissions follow Gorape project/group role bindings.',
    '強い方で表示されます（Gorapeのeffective roleと同じ考え方）。':
        'the stronger role is shown, matching Gorape effective-role resolution.',
    '所有証明ではBase64urlチャレンジを生バイト列に戻し、':
        'For proof of possession, decode the Base64url challenge to raw bytes and ',
    '既存CLI用の http://127.0.0.1:8400/callback は変更・削除しません。':
        'The existing CLI callback http://127.0.0.1:8400/callback is preserved.',
    '有効ロールはプロジェクトロールとグループロールの強い方です。':
        'The effective role is the stronger of the project and group roles.',
    '権限はログインするKeycloakアカウントで決まります。':
        'Permissions are determined by the signed-in Keycloak account.',
    '正規のRedirect URIを使用してください。': 'Use a registered redirect URI.',
    '登録後、チャレンジ署名による所有証明を実行できます。':
        'After registration, prove possession by signing a challenge.',
    '管理者: グループの作成・編集・削除、グループロールの付与が可能です。':
        'Admin: can create/edit/delete groups and grant group roles.',
    '管理者または編集者のロールが必要です。': 'An administrator or editor role is required.',
    '続けてチャレンジ署名による所有証明を実行できます。':
        'You can then prove possession by signing a challenge.',
    '編集者: グループ内のデバイス割当を変更できます。グループ自体の作成・削除は管理者のみです。':
        'Editor: can change group device assignments. Only admins can create or delete groups.',
    '編集者: デバイス失効とグループへのデバイス割当が可能です。':
        'Editor: can revoke devices and assign devices to groups.',
    '行いません。App AttestやSecure Enclaveを利用するには':
        'is not performed. To use App Attest or Secure Enclave, ',
    '設定するまで登録は失敗します。': 'Registration will fail until configured.',
    '証明書チェーン（leaf-first）': 'Certificate chain (leaf first)',
    '閲覧者: グループとデバイスを参照できます。': 'Viewer: can view groups and devices.',
    '対応状況': 'Support',
    'アクセストークンにgroupsクレームがありません。': 'The access token has no groups claim.',
    'プロジェクトがまだ作成されていません。': 'No projects have been created yet.',
    'Attestation証拠': 'Attestation evidence',
    'このスコープではデバイスを登録できません。':
        'Device registration is unavailable in this scope.',
    'このスコープのロールがありません。': 'No role is assigned for this scope.',
    'このビルドでは取得できません': 'Unavailable in this build',
    'この画面の値は端末内に保存される希望値です。': 'These are preferences stored on this device.',
    'この設定は表示上の希望値であり、登録可否を変えません。':
        'This preference is informational and does not affect registration eligibility.',
    'このアプリはパスキーの秘密情報を保存せず、': 'This app does not store passkey secrets; ',
    'ただしGorapeのAttestation VerifierはiOS/macOSを':
        'However, the Gorape Attestation Verifier does not support iOS/macOS ',
    'グループの作成・削除やロール付与は管理者のみ表示されます。':
        'Only administrators can create/delete groups or assign roles.',
    'グループへのデバイス追加・削除が可能です。グループ編集・削除とロール付与は管理者のみです。':
        'Can add/remove devices in groups. Only administrators can edit/delete groups or assign roles.',
    'グループ作成とロール付与は管理者のみです。':
        'Only administrators can create groups and assign roles.',
    'グループ情報と割り当てデバイスを参照できます。追加・削除は表示されません。':
        'Can view group information and assigned devices. Add/remove actions are unavailable.',
    'ステータス': 'Status',
    'ソフトウェア': 'Software',
    'デバイスを登録': 'Register device',
    'デバイスポリシー': 'Device policy',
    'ハードウェア': 'Hardware',
    'ローカルKeycloakの例: admin CLIで clients/gorape-client の':
        'Local Keycloak example: use the admin CLI to update clients/gorape-client ',
    '別のユーザーを使う場合は、ログアウトしてから再ログインしてください。':
        'To switch users, sign out and sign in again.',
    '変更後は再ログイン（またはトークン更新）で反映されます。':
        'Sign in again or refresh the token for changes to take effect.',
    '接続設定を開く': 'Open connection settings',
    '「Gorape」はバックエンドのVerifier対応状況です。':
        '“Gorape” shows backend verifier support.',
    '「アプリ側」はFlutterクライアントの実装状況、':
        '“App” shows Flutter client implementation status; ',
    '「管理」タブではKeycloakトークンのロールとグループを確認できます。':
        'Check Keycloak token roles and groups in the Management tab.',
    'クラスタ全体のロール確認に加えて、各プロジェクトの管理画面へ移動できます。':
        'Review cluster roles and open each project management view.',
    'Gorape APIにはアクセストークンのみを送信します。':
        'Only the access token is sent to the Gorape API.',
    'Access TokenのみをGorape APIへ送信します。ID TokenはAPI認証情報として使用しません。':
        'Only the access token is sent to the Gorape API; the ID token is never used for API authentication.',
    'Access TokenはGorape APIのBearer認証にのみ使用します。':
        'The access token is only used as a Gorape API bearer credential.',
    'ID Tokenは送信しません。': 'The ID token is not sent.',
    'APIは既定で 10.0.2.2:8000 を利用します。': 'The API defaults to 10.0.2.2:8000.',
    'Android Emulatorは 10.0.2.2、実機はPCのLAN IPを指定してください。':
        'Use 10.0.2.2 for Android emulators and your PC LAN IP for physical devices.',
    'Android Emulatorでは OIDC 用に': 'For OIDC on Android emulators, ',
    '`adb reverse tcp:8080 tcp:8080` を実行してください。':
        'run `adb reverse tcp:8080 tcp:8080`.',
    '保存に失敗しました: ': 'Save failed: ',
    '表示名を入力してください。': 'Enter a display name.',
    'この端末には該当デバイスの秘密鍵がありません。':
        'The private key for this device is not on this device.',
    'Android実機でOS保護鍵を生成し、Gorapeへ登録してください。':
        'Generate an OS-protected key on a physical Android device and register it with Gorape.',
    'この端末の鍵': 'Key on this device',
    '名前': 'Name',
    'グループロールがありません。': 'No group roles.',
  };

  static String translate(material.BuildContext context, String? source) {
    if (source == null) return '';
    if (material.Localizations.localeOf(context).languageCode != 'en') {
      return source;
    }
    final exact = _english[source];
    if (exact != null) return exact;

    final count = RegExp(r'^(\d+) 台$').firstMatch(source);
    if (count != null) {
      return '${count.group(1)} devices';
    }
    final items = RegExp(r'^(\d+) 件$').firstMatch(source);
    if (items != null) {
      return '${items.group(1)} items';
    }
    final extraDevices = RegExp(r'^ほか (\d+) 台（デバイスタブで確認）$').firstMatch(source);
    if (extraDevices != null) {
      return '${extraDevices.group(1)} more (see Devices tab)';
    }
    final project = RegExp(r'^プロジェクト「(.+)」$').firstMatch(source);
    if (project != null) {
      return 'Project “${project.group(1)}”';
    }
    final group = RegExp(r'^グループ「(.+)」$').firstMatch(source);
    if (group != null) {
      return 'Group “${group.group(1)}”';
    }
    final scopedProject = RegExp(r'^プロジェクト「(.+)」のロール$').firstMatch(source);
    if (scopedProject != null) {
      return 'Project “${scopedProject.group(1)}” role';
    }
    final scopedGroup = RegExp(r'^グループ「(.+)」のロール$').firstMatch(source);
    if (scopedGroup != null) {
      return 'Group “${scopedGroup.group(1)}” role';
    }
    final createdGroup = RegExp(r'^グループ「(.+)」を作成しました。$').firstMatch(source);
    if (createdGroup != null) {
      return 'Group “${createdGroup.group(1)}” created.';
    }
    final deletedGroup = RegExp(r'^「(.+)」を削除します。元に戻せません。$').firstMatch(source);
    if (deletedGroup != null) {
      return 'Delete “${deletedGroup.group(1)}”? This cannot be undone.';
    }
    final revokedDevice = RegExp(
      r'^(.+) をGorape側でrevokedにします。元に戻せません。$',
    ).firstMatch(source);
    if (revokedDevice != null) {
      return 'Revoke ${revokedDevice.group(1)} in Gorape? This cannot be undone.';
    }
    final saveFailure = RegExp(r'^保存に失敗しました: (.*)$').firstMatch(source);
    if (saveFailure != null) return 'Could not save: ${saveFailure.group(1)}';
    final response = RegExp(r'^応答: (.*)$').firstMatch(source);
    if (response != null) return 'Response: ${response.group(1)}';
    final currentDevice = RegExp(
      r'^この端末: (.+)。Keycloakログインはflutter_appauthで対応します。$',
    ).firstMatch(source);
    if (currentDevice != null) {
      return 'This device: ${currentDevice.group(1)}. Keycloak sign-in uses flutter_appauth.';
    }
    if (source.startsWith('この端末: ')) {
      final period = source.indexOf('。');
      if (period > 0) {
        final device = source.substring('この端末: '.length, period);
        final details = source.substring(period + 1).trim();
        return 'This device: $device. ${translate(context, details)}';
      }
    }
    final displayScopeRole = RegExp(r'^(.+)のロール$').firstMatch(source);
    if (displayScopeRole != null) {
      return '${translate(context, displayScopeRole.group(1))} role';
    }
    final noScopeRole = RegExp(r'^(.+)のロールがありません$').firstMatch(source);
    if (noScopeRole != null) {
      return 'No role is assigned for ${translate(context, noScopeRole.group(1))}';
    }
    final removedFromGroup = RegExp(r'^(.+) をグループから外しました。$').firstMatch(source);
    if (removedFromGroup != null) {
      return '${removedFromGroup.group(1)} removed from the group.';
    }
    final separator = source.indexOf(': ');
    if (separator > 0) {
      final title = source.substring(0, separator);
      final message = source.substring(separator + 2);
      final translatedTitle = _english[title];
      final translatedMessage = _english[message];
      if (translatedTitle != null || translatedMessage != null) {
        return '${translatedTitle ?? title}: ${translatedMessage ?? message}';
      }
    }

    var translated = source;
    final phrases = [..._english.entries, ..._englishFragments.entries]
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final phrase in phrases) {
      if (phrase.key.length >= 4) {
        translated = translated.replaceAll(phrase.key, phrase.value);
      }
    }
    return translated;
  }
}

String tr(material.BuildContext context, String source) =>
    AppStrings.translate(context, source);
