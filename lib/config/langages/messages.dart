/// Central Japanese/English message catalog. UI code refers to stable MCODE IDs.
final class AppMessage {
  const AppMessage({required this.ja, required this.en});
  final String ja;
  final String en;
}

const Map<String, AppMessage> appMessageCatalog = <String, AppMessage>{
  "MCODE-00001": AppMessage(ja: "設定エラー", en: "Settings error"),
  "MCODE-00002": AppMessage(ja: "ネットワークエラー", en: "Network error"),
  "MCODE-00003": AppMessage(ja: "リクエストが不正です", en: "Invalid request"),
  "MCODE-00004": AppMessage(ja: "認証が必要です", en: "Authentication required"),
  "MCODE-00005": AppMessage(ja: "権限がありません", en: "Permission denied"),
  "MCODE-00006": AppMessage(ja: "見つかりません", en: "Not found"),
  "MCODE-00007": AppMessage(ja: "検証に失敗しました", en: "Validation failed"),
  "MCODE-00008": AppMessage(ja: "サーバーエラー", en: "Server error"),
  "MCODE-00009": AppMessage(ja: "ログインエラー", en: "Login error"),
  "MCODE-00010": AppMessage(
    ja: "ログインがキャンセルされました。",
    en: "Sign-in was cancelled.",
  ),
  "MCODE-00011": AppMessage(ja: "ログインをキャンセルしました", en: "Sign-in cancelled"),
  "MCODE-00012": AppMessage(
    ja: "このOSではログイン未対応です",
    en: "Sign-in is not supported on this OS",
  ),
  "MCODE-00013": AppMessage(ja: "バックエンドが未対応です", en: "Backend not supported"),
  "MCODE-00014": AppMessage(ja: "デバイス鍵が見つかりません", en: "Device key not found"),
  "MCODE-00015": AppMessage(ja: "チャレンジが無効です", en: "Invalid challenge"),
  "MCODE-00016": AppMessage(
    ja: "ポリシーAPIは未提供です",
    en: "Policy API is unavailable",
  ),
  "MCODE-00017": AppMessage(
    ja: "操作をキャンセルしました。",
    en: "The operation was cancelled.",
  ),
  "MCODE-00018": AppMessage(ja: "キャンセルしました", en: "Cancelled"),
  "MCODE-00019": AppMessage(ja: "エラーが発生しました", en: "An error occurred"),
  "MCODE-00020": AppMessage(ja: "データ形式エラー", en: "Data format error"),
  "MCODE-00021": AppMessage(
    ja: "サーバーの応答を解釈できませんでした。",
    en: "Could not read the server response.",
  ),
  "MCODE-00022": AppMessage(ja: "予期しないエラー", en: "Unexpected error"),
  "MCODE-00023": AppMessage(ja: "権限なし", en: "No access"),
  "MCODE-00024": AppMessage(ja: "閲覧者", en: "Viewer"),
  "MCODE-00025": AppMessage(ja: "編集者", en: "Editor"),
  "MCODE-00026": AppMessage(ja: "管理者", en: "Administrator"),
  "MCODE-00027": AppMessage(
    ja: "グループ作成・ロール付与・デバイス失効など、このスコープの管理操作をすべて実行できます。",
    en: "Can manage this scope, including groups, role assignments, and device revocation.",
  ),
  "MCODE-00028": AppMessage(
    ja: "デバイスの登録・失効、グループへのデバイス割当を実行できます。グループ設定とロール付与は変更できません。",
    en: "Can register and revoke devices and assign devices to groups. Cannot manage groups or roles.",
  ),
  "MCODE-00029": AppMessage(
    ja: "デバイス、グループ、ロールを参照できます。変更操作は表示されません。",
    en: "Can view devices, groups, and roles. Editing actions are unavailable.",
  ),
  "MCODE-00030": AppMessage(
    ja: "このスコープのロールがKeycloakトークンに含まれていません。",
    en: "The Keycloak token has no role for this scope.",
  ),
  "MCODE-00031": AppMessage(ja: "参照", en: "View"),
  "MCODE-00032": AppMessage(ja: "編集操作", en: "Edit"),
  "MCODE-00033": AppMessage(ja: "管理操作", en: "Manage"),
  "MCODE-00034": AppMessage(
    ja: "アクセストークンへマッピングしてください。",
    en: "Map these claims to the access token. ",
  ),
  "MCODE-00035": AppMessage(
    ja: "設定変更後は再ログインで反映されます。",
    en: "Sign in again for changes to take effect.",
  ),
  "MCODE-00036": AppMessage(ja: "再試行", en: "Retry"),
  "MCODE-00037": AppMessage(ja: "読み込み中...", en: "Loading…"),
  "MCODE-00038": AppMessage(ja: "設定を読み込み中...", en: "Loading settings…"),
  "MCODE-00039": AppMessage(ja: "ログインしています...", en: "Signing in…"),
  "MCODE-00040": AppMessage(ja: "セッションを確認中...", en: "Checking session…"),
  "MCODE-00041": AppMessage(
    ja: "接続設定を読み込み中...",
    en: "Loading connection settings…",
  ),
  "MCODE-00042": AppMessage(ja: "プロジェクトを読み込み中...", en: "Loading projects…"),
  "MCODE-00043": AppMessage(ja: "デバイスを読み込み中...", en: "Loading devices…"),
  "MCODE-00044": AppMessage(
    ja: "Verifier対応状況を取得中...",
    en: "Loading verifier support…",
  ),
  "MCODE-00045": AppMessage(ja: "ポリシーを読み込み中...", en: "Loading policy…"),
  "MCODE-00046": AppMessage(ja: "GorapeFlutter", en: "GorapeFlutter"),
  "MCODE-00047": AppMessage(ja: "表示言語", en: "Display language"),
  "MCODE-00048": AppMessage(ja: "言語", en: "Language"),
  "MCODE-00049": AppMessage(ja: "日本語", en: "Japanese"),
  "MCODE-00050": AppMessage(ja: "設定", en: "Settings"),
  "MCODE-00051": AppMessage(ja: "デバイス", en: "Devices"),
  "MCODE-00052": AppMessage(ja: "デバイス登録", en: "Register device"),
  "MCODE-00053": AppMessage(ja: "登録", en: "Register"),
  "MCODE-00054": AppMessage(ja: "対応状況", en: "Support"),
  "MCODE-00055": AppMessage(ja: "ポリシー", en: "Policy"),
  "MCODE-00056": AppMessage(ja: "管理", en: "Manage"),
  "MCODE-00057": AppMessage(ja: "ログアウト", en: "Sign out"),
  "MCODE-00058": AppMessage(ja: "接続設定", en: "Connection settings"),
  "MCODE-00059": AppMessage(
    ja: "接続設定・Redirect URI",
    en: "Connection settings / Redirect URI",
  ),
  "MCODE-00060": AppMessage(ja: "アカウント", en: "Account"),
  "MCODE-00061": AppMessage(ja: "アカウント登録", en: "Create account"),
  "MCODE-00062": AppMessage(ja: "閉じる", en: "Close"),
  "MCODE-00063": AppMessage(
    ja: "以下のURLをブラウザで開いてアカウントを登録してください。",
    en: "Open the following URL in a browser to create an account.",
  ),
  "MCODE-00064": AppMessage(
    ja: "管理者機能を使う場合は、管理者ロールを持つKeycloakアカウントでログインしてください。権限を切り替える場合は、ログアウトしてから再ログインしてください。",
    en: "To use admin features, sign in with a Keycloak account that has the admin role. Sign out before switching accounts.",
  ),
  "MCODE-00065": AppMessage(ja: "Keycloakでログイン", en: "Sign in with Keycloak"),
  "MCODE-00066": AppMessage(ja: "管理者ログイン", en: "Admin sign in"),
  "MCODE-00067": AppMessage(
    ja: "Keycloakへ接続中...",
    en: "Connecting to Keycloak…",
  ),
  "MCODE-00068": AppMessage(
    ja: "Keycloakでサインインし、OS保護鍵をGorapeに登録します。パスキーとMFAはKeycloak、デバイス検証はGorapeが担当します。",
    en: "Sign in with Keycloak, then register an OS-protected key with Gorape. Keycloak handles passkeys and MFA; Gorape verifies devices.",
  ),
  "MCODE-00069": AppMessage(ja: "OS別の対応状況", en: "Platform support"),
  "MCODE-00070": AppMessage(ja: "対応", en: "Supported"),
  "MCODE-00071": AppMessage(ja: "未対応", en: "Unsupported"),
  "MCODE-00072": AppMessage(ja: "接続先", en: "Endpoints"),
  "MCODE-00073": AppMessage(ja: "Gorape API", en: "Gorape API"),
  "MCODE-00074": AppMessage(ja: "Keycloak / OIDC", en: "Keycloak / OIDC"),
  "MCODE-00075": AppMessage(ja: "API Base URL", en: "API base URL"),
  "MCODE-00076": AppMessage(ja: "OIDC Issuer", en: "OIDC issuer"),
  "MCODE-00077": AppMessage(ja: "Client ID", en: "Client ID"),
  "MCODE-00078": AppMessage(ja: "Redirect URI", en: "Redirect URI"),
  "MCODE-00079": AppMessage(
    ja: "Keycloak Redirect URI許可リスト",
    en: "Keycloak redirect URI allowlist",
  ),
  "MCODE-00080": AppMessage(ja: "ヘルスチェック", en: "Health check"),
  "MCODE-00081": AppMessage(ja: "コピー", en: "Copy"),
  "MCODE-00082": AppMessage(
    ja: "Keycloakの gorape-client に以下を登録してください。既存CLI用の http://127.0.0.1:8400/callback は変更・削除しません。",
    en: "Add these URIs to the Keycloak gorape-client. The existing CLI callback will be preserved.",
  ),
  "MCODE-00083": AppMessage(
    ja: "ローカルKeycloakの例: admin CLIで clients/gorape-client の redirectUris に追加します。詳細は README を参照してください。",
    en: "For local Keycloak, add these to clients/gorape-client redirectUris using the admin CLI. See the README.",
  ),
  "MCODE-00084": AppMessage(
    ja: "HTTP接続はローカル開発専用です。本番ではHTTPSと正規のRedirect URIを使用してください。",
    en: "HTTP is for local development only. Use HTTPS and an approved redirect URI in production.",
  ),
  "MCODE-00085": AppMessage(ja: "保存", en: "Save"),
  "MCODE-00086": AppMessage(ja: "保存中...", en: "Saving…"),
  "MCODE-00087": AppMessage(ja: "初期値に戻す", en: "Restore defaults"),
  "MCODE-00088": AppMessage(ja: "セッション", en: "Session"),
  "MCODE-00089": AppMessage(
    ja: "ログイン前に接続先を確認できます。保存後に戻ってログインしてください。",
    en: "Check the endpoints before signing in. Save and return to sign in.",
  ),
  "MCODE-00090": AppMessage(
    ja: "ログアウトするとKeycloakのセッション終了を試行し、ローカルのトークンを削除します。",
    en: "Signing out attempts to end the Keycloak session and removes local tokens.",
  ),
  "MCODE-00091": AppMessage(
    ja: "Access TokenはGorape APIのBearer認証にのみ使用します。デバイス秘密鍵はOSキーストアから出ません。",
    en: "The access token is only used for Gorape API authentication. Device private keys stay in the OS keystore.",
  ),
  "MCODE-00092": AppMessage(
    ja: "Redirect URIをコピーしました。",
    en: "Redirect URIs copied.",
  ),
  "MCODE-00093": AppMessage(
    ja: "接続設定を保存しました。",
    en: "Connection settings saved.",
  ),
  "MCODE-00094": AppMessage(ja: "初期値に戻しました。", en: "Defaults restored."),
  "MCODE-00095": AppMessage(
    ja: "HTTPの開発用接続です。本番ではHTTPSを使用してください。",
    en: "This is an HTTP development connection. Use HTTPS in production.",
  ),
  "MCODE-00096": AppMessage(
    ja: "Android Emulatorは 10.0.2.2、実機はPCのLAN IPを指定してください。adb reverse を使う場合は localhost:8000 も利用できます。",
    en: "Use 10.0.2.2 for Android emulators, your computer’s LAN IP for physical devices, or localhost:8000 with adb reverse.",
  ),
  "MCODE-00097": AppMessage(
    ja: "Android Emulatorでは OIDC 用に `adb reverse tcp:8080 tcp:8080` を実行してください。APIは既定で 10.0.2.2:8000 を利用します。",
    en: "For Android emulators, run `adb reverse tcp:8080 tcp:8080` for OIDC. The API defaults to 10.0.2.2:8000.",
  ),
  "MCODE-00098": AppMessage(ja: "Android端末を登録", en: "Register Android device"),
  "MCODE-00099": AppMessage(ja: "この端末", en: "This device"),
  "MCODE-00100": AppMessage(ja: "Gorapeバックエンド", en: "Gorape backend"),
  "MCODE-00101": AppMessage(
    ja: "Verifier対応状況を更新",
    en: "Refresh verifier support",
  ),
  "MCODE-00102": AppMessage(ja: "登録情報", en: "Registration details"),
  "MCODE-00103": AppMessage(ja: "表示名", en: "Display name"),
  "MCODE-00104": AppMessage(ja: "例: Pixel 8 Pro", en: "e.g. Pixel 8 Pro"),
  "MCODE-00105": AppMessage(
    ja: "チャレンジを取得して登録",
    en: "Get challenge and register",
  ),
  "MCODE-00106": AppMessage(ja: "登録しています...", en: "Registering…"),
  "MCODE-00107": AppMessage(
    ja: "このOSではOS保護鍵とAttestationが未実装のため登録できません。",
    en: "Registration is unavailable because protected keys and attestation are not implemented on this OS.",
  ),
  "MCODE-00108": AppMessage(
    ja: "デバイス登録にはプロジェクトのeditor以上のロールが必要です。",
    en: "Device registration requires the project editor role or higher.",
  ),
  "MCODE-00109": AppMessage(ja: "登録フローの詳細", en: "Registration flow details"),
  "MCODE-00110": AppMessage(ja: "デバイスを登録しました", en: "Device registered"),
  "MCODE-00111": AppMessage(
    ja: "バックエンドがAttestationをverifiedとして記録しました。続けてチャレンジ署名による所有証明を実行できます。",
    en: "The backend recorded the attestation as verified. You can now prove key possession by signing a challenge.",
  ),
  "MCODE-00112": AppMessage(ja: "一覧へ", en: "Back to list"),
  "MCODE-00113": AppMessage(ja: "デバイス一覧を開く", en: "Open device list"),
  "MCODE-00114": AppMessage(ja: "登録済みデバイス", en: "Registered devices"),
  "MCODE-00115": AppMessage(
    ja: "閲覧者のためデバイスを登録できません。管理者または編集者のロールが必要です。",
    en: "Viewers cannot register devices. An administrator or editor role is required.",
  ),
  "MCODE-00116": AppMessage(
    ja: "このスコープではデバイスを登録できません。管理者または編集者のロールが必要です。",
    en: "You cannot register devices in this scope. An administrator or editor role is required.",
  ),
  "MCODE-00117": AppMessage(
    ja: "参照はGorape側の権限に従いますが、登録・失効などの変更操作は無効です。閲覧者のため、デバイスの登録・失効は実行できません。",
    en: "Viewing follows Gorape permissions, but changes are disabled for viewers.",
  ),
  "MCODE-00118": AppMessage(
    ja: "閲覧者のため、デバイスの登録・失効は実行できません。",
    en: "Viewers cannot register or revoke devices.",
  ),
  "MCODE-00119": AppMessage(
    ja: "Android実機でOS保護鍵を生成し、Gorapeへ登録してください。登録後、チャレンジ署名による所有証明を実行できます。",
    en: "Generate a protected key on an Android device and register it with Gorape. Then prove possession by signing a challenge.",
  ),
  "MCODE-00120": AppMessage(ja: "デバイスが登録されていません", en: "No devices registered"),
  "MCODE-00121": AppMessage(
    ja: "デバイスが登録されていません。",
    en: "No devices are registered.",
  ),
  "MCODE-00122": AppMessage(ja: "この端末の鍵", en: "Key on this device"),
  "MCODE-00123": AppMessage(ja: "デバイス詳細", en: "Device details"),
  "MCODE-00124": AppMessage(ja: "再読み込み", en: "Refresh"),
  "MCODE-00125": AppMessage(ja: "デバイス操作", en: "Device actions"),
  "MCODE-00126": AppMessage(
    ja: "参照はできますが、所有証明・失効は実行できません。閲覧者のため、所有証明とデバイス失効は実行できません。",
    en: "View access is available, but proof and revocation are disabled for viewers.",
  ),
  "MCODE-00127": AppMessage(
    ja: "閲覧者のため、所有証明とデバイス失効は実行できません。",
    en: "Viewers cannot prove possession or revoke devices.",
  ),
  "MCODE-00128": AppMessage(ja: "デバイス状態", en: "Device status"),
  "MCODE-00129": AppMessage(ja: "デバイスID", en: "Device ID"),
  "MCODE-00130": AppMessage(ja: "プラットフォーム", en: "Platform"),
  "MCODE-00131": AppMessage(ja: "登録日時", en: "Registered"),
  "MCODE-00132": AppMessage(ja: "最終検証", en: "Last verified"),
  "MCODE-00133": AppMessage(ja: "失効日時", en: "Revoked"),
  "MCODE-00134": AppMessage(ja: "バージョン", en: "Version"),
  "MCODE-00135": AppMessage(
    ja: "この端末には該当デバイスの秘密鍵がありません。\n他端末で登録されたデバイスは表示・失効のみ可能です。",
    en: "The private key for this device is not on this device. Devices registered elsewhere can only be viewed or revoked.",
  ),
  "MCODE-00136": AppMessage(ja: "ローカル登録", en: "Registered locally"),
  "MCODE-00137": AppMessage(ja: "操作", en: "Actions"),
  "MCODE-00138": AppMessage(
    ja: "チャレンジ署名で所有証明",
    en: "Prove possession by signing a challenge",
  ),
  "MCODE-00139": AppMessage(ja: "デバイスを失効", en: "Revoke device"),
  "MCODE-00140": AppMessage(
    ja: "所有証明ではBase64urlチャレンジを生バイト列に戻し、OS鍵で署名します。ECDSAはASN.1 DER、RSAはPKCS#1 v1.5/SHA-256、Ed25519は生バイト列です。",
    en: "The Base64url challenge is decoded and signed with the OS key. ECDSA uses ASN.1 DER; RSA uses PKCS#1 v1.5/SHA-256; Ed25519 uses raw bytes.",
  ),
  "MCODE-00141": AppMessage(ja: "最新の記録を取得", en: "Refresh records"),
  "MCODE-00142": AppMessage(ja: "Attestation記録", en: "Attestation records"),
  "MCODE-00143": AppMessage(
    ja: "Attestation記録はありません。",
    en: "No attestation records.",
  ),
  "MCODE-00144": AppMessage(
    ja: "チャレンジ署名をGorapeが検証しました。",
    en: "Gorape verified the challenge signature.",
  ),
  "MCODE-00145": AppMessage(ja: "デバイスを失効しますか？", en: "Revoke this device?"),
  "MCODE-00146": AppMessage(
    ja: "この端末のローカル鍵も削除されます。元に戻せません。",
    en: "The local key on this device will also be deleted. This cannot be undone.",
  ),
  "MCODE-00147": AppMessage(ja: "キャンセル", en: "Cancel"),
  "MCODE-00148": AppMessage(ja: "失効する", en: "Revoke"),
  "MCODE-00149": AppMessage(ja: "デバイスを失効しました。", en: "Device revoked."),
  "MCODE-00150": AppMessage(
    ja: "Android端末でOS保護鍵を生成し、Gorapeへ登録してください。",
    en: "Generate an OS-protected key on an Android device and register it with Gorape.",
  ),
  "MCODE-00151": AppMessage(
    ja: "チャレンジ署名の所有証明を実行できます。",
    en: "You can prove key possession by signing a challenge.",
  ),
  "MCODE-00152": AppMessage(
    ja: "デバイスポリシー（ローカルのみ）",
    en: "Device policy (local only)",
  ),
  "MCODE-00153": AppMessage(
    ja: "この画面の値は端末内に保存される希望値です。Gorapeバックエンドでは強制されません。",
    en: "These preferences are stored on this device and are not enforced by the Gorape backend.",
  ),
  "MCODE-00154": AppMessage(ja: "バックエンドAPI未提供", en: "Backend API unavailable"),
  "MCODE-00155": AppMessage(ja: "ローカルポリシーを保存しました。", en: "Local policy saved."),
  "MCODE-00156": AppMessage(ja: "ログインとデバイス鍵", en: "Sign-in and device keys"),
  "MCODE-00157": AppMessage(
    ja: "ログイン後の所有証明を推奨",
    en: "Recommend proof of possession after sign-in",
  ),
  "MCODE-00158": AppMessage(
    ja: "Attestationなしのデバイスを許可",
    en: "Allow devices without attestation",
  ),
  "MCODE-00159": AppMessage(
    ja: "バックエンドの登録APIはAttestation証拠を要求します。この設定は表示上の希望値であり、登録可否を変えません。",
    en: "The registration API requires attestation evidence. This preference is informational and does not change registration eligibility.",
  ),
  "MCODE-00160": AppMessage(ja: "パスキーとデバイス鍵", en: "Passkeys and device keys"),
  "MCODE-00161": AppMessage(
    ja: "デバイス専用鍵（推奨）",
    en: "Device-bound key (recommended)",
  ),
  "MCODE-00162": AppMessage(
    ja: "Keycloakの共有パスキー",
    en: "Shared Keycloak passkey",
  ),
  "MCODE-00163": AppMessage(
    ja: "パスキーはKeycloakアカウントに紐づき、複数端末で共有されます。このアプリはパスキー秘密情報を保存しません。",
    en: "Passkeys belong to the Keycloak account and can be shared across devices. This app never stores passkey secrets.",
  ),
  "MCODE-00164": AppMessage(
    ja: "パスキー・MFA・アカウント回復はKeycloakの責務です。このアプリはパスキー秘密情報を保存せず、Gorapeはデバイス公開鍵と所有証明を扱います。",
    en: "Keycloak handles passkeys, MFA, and account recovery. This app stores no passkey secrets; Gorape handles device public keys and proof of possession.",
  ),
  "MCODE-00165": AppMessage(ja: "この設定の扱い", en: "About these settings"),
  "MCODE-00166": AppMessage(
    ja: "現行のGorape OpenAPI 3.1にはデバイスポリシー設定APIがありません。この画面の設定は端末内の希望値であり、バックエンドで強制されません。デバイスポリシーAPIを追加してから接続してください。",
    en: "The current Gorape OpenAPI 3.1 has no device policy API. These are local preferences and are not enforced by the backend.",
  ),
  "MCODE-00167": AppMessage(ja: "バックエンド対応状況を更新", en: "Refresh backend support"),
  "MCODE-00168": AppMessage(
    ja: "Android Key Attestation",
    en: "Android Key Attestation",
  ),
  "MCODE-00169": AppMessage(ja: "iOS / macOS", en: "iOS / macOS"),
  "MCODE-00170": AppMessage(
    ja: "Windows / Linux / Web",
    en: "Windows / Linux / Web",
  ),
  "MCODE-00171": AppMessage(ja: "対応マトリクス", en: "Support matrix"),
  "MCODE-00172": AppMessage(ja: "ログイン", en: "Sign-in"),
  "MCODE-00173": AppMessage(ja: "OS鍵", en: "OS key"),
  "MCODE-00174": AppMessage(ja: "Attestation", en: "Attestation"),
  "MCODE-00175": AppMessage(ja: "Gorape", en: "Gorape"),
  "MCODE-00176": AppMessage(ja: "Keycloakログイン", en: "Keycloak sign-in"),
  "MCODE-00177": AppMessage(ja: "OS保護鍵の生成", en: "Protected key generation"),
  "MCODE-00178": AppMessage(
    ja: "Attestation（バックエンド）",
    en: "Attestation (backend)",
  ),
  "MCODE-00179": AppMessage(
    ja: "Android Keystore + Key Attestation。バックエンドの信頼アンカー設定が必要です。",
    en: "Android Keystore + Key Attestation. Backend trust anchors must be configured.",
  ),
  "MCODE-00180": AppMessage(
    ja: "Keycloakログインのみ対応。AttestationはGorapeバックエンドがunsupportedを返します。",
    en: "Keycloak sign-in is supported. The Gorape backend reports attestation as unsupported.",
  ),
  "MCODE-00181": AppMessage(
    ja: "iOS/macOS/AndroidのみKeycloakログインを提供します。Windows向けflutter_appauth実装がありません。",
    en: "Keycloak sign-in is available on iOS, macOS, and Android. Windows has no flutter_appauth implementation.",
  ),
  "MCODE-00182": AppMessage(ja: "クラスタ", en: "Cluster"),
  "MCODE-00183": AppMessage(ja: "プロジェクト", en: "Project"),
  "MCODE-00184": AppMessage(ja: "グループ", en: "Groups"),
  "MCODE-00185": AppMessage(ja: "プロジェクトがありません", en: "No project"),
  "MCODE-00186": AppMessage(
    ja: "管理対象のプロジェクトがありません。クラスタ表示のみ利用できます。",
    en: "There are no projects to manage. Only the cluster view is available.",
  ),
  "MCODE-00187": AppMessage(
    ja: "クラスタ（Keycloak realm）",
    en: "Cluster (Keycloak realm)",
  ),
  "MCODE-00188": AppMessage(
    ja: "クラスタのロールはKeycloakのrealm/clientロールから判定しています。",
    en: "Cluster roles are resolved from Keycloak realm and client roles.",
  ),
  "MCODE-00189": AppMessage(
    ja: "クラスタ情報は参照のみ表示されます。ロールやグループの変更は表示されません。",
    en: "Cluster information is read-only. Role and group changes are unavailable.",
  ),
  "MCODE-00190": AppMessage(ja: "管理者ビュー", en: "Administrator view"),
  "MCODE-00191": AppMessage(
    ja: "クラスタ全体のロール確認に加えて、各プロジェクトの管理画面へ移動できます。実際の作成・変更権限はGorapeのproject/groupロール付与に従います。",
    en: "Review cluster roles and open project management. Gorape project/group role bindings control actual permissions.",
  ),
  "MCODE-00192": AppMessage(ja: "サインイン情報", en: "Sign-in information"),
  "MCODE-00193": AppMessage(ja: "ユーザー名", en: "Username"),
  "MCODE-00194": AppMessage(ja: "メール", en: "Email"),
  "MCODE-00195": AppMessage(ja: "Keycloakロール", en: "Keycloak roles"),
  "MCODE-00196": AppMessage(
    ja: "realm_access/resource_accessにロールがありません。",
    en: "No roles in realm_access/resource_access.",
  ),
  "MCODE-00197": AppMessage(ja: "Keycloakグループ", en: "Keycloak groups"),
  "MCODE-00198": AppMessage(
    ja: "アクセストークンにgroupsクレームがありません。",
    en: "The access token has no groups claim.",
  ),
  "MCODE-00199": AppMessage(ja: "プロジェクト別ロール", en: "Project roles"),
  "MCODE-00200": AppMessage(
    ja: "表示可能なプロジェクトがありません。",
    en: "No projects are visible.",
  ),
  "MCODE-00201": AppMessage(
    ja: "Keycloak属性（gorape_*）",
    en: "Keycloak attributes (gorape_*)",
  ),
  "MCODE-00202": AppMessage(
    ja: "ロール表示の切り替え方",
    en: "How role views are selected",
  ),
  "MCODE-00203": AppMessage(ja: "ロールの確認方法", en: "How to check roles"),
  "MCODE-00204": AppMessage(
    ja: "ロールを変えると、この画面は管理者・編集者・閲覧者のいずれかに切り替わります。変更後は再ログイン（またはトークン更新）で反映されます。",
    en: "This view changes based on your administrator, editor, or viewer role. Sign in again or refresh the token after changing roles.",
  ),
  "MCODE-00205": AppMessage(
    ja: "Keycloakトークンのロール表示と、Gorape DBのproject/groupロール付与は別に管理されています。管理操作にはGorape側でadmin/editorの付与が必要です。",
    en: "Keycloak token roles and Gorape DB project/group bindings are managed separately. Management actions also require Gorape permissions.",
  ),
  "MCODE-00206": AppMessage(
    ja: "このIssuerのGorapeプロジェクトがbootstrap済みかも確認してください。",
    en: "Also verify that a Gorape project has been bootstrapped for this issuer.",
  ),
  "MCODE-00207": AppMessage(ja: "プロジェクト情報", en: "Project information"),
  "MCODE-00208": AppMessage(ja: "グループ一覧", en: "Groups"),
  "MCODE-00209": AppMessage(
    ja: "グループがありません。右上の「作成」から追加できます。",
    en: "No groups yet. Use Create to add one.",
  ),
  "MCODE-00210": AppMessage(
    ja: "グループが作成されていません。",
    en: "No groups have been created.",
  ),
  "MCODE-00211": AppMessage(
    ja: "各グループのロールは、プロジェクトロールとKeycloakのグループ別ロールの強い方で表示されます（Gorapeのeffective roleと同じ考え方）。",
    en: "Each group shows the stronger of its project role and Keycloak group role, matching Gorape effective-role resolution.",
  ),
  "MCODE-00212": AppMessage(
    ja: "プロジェクト、グループ、デバイスを参照できます。作成・変更・失効の操作は表示されません。",
    en: "Can view projects, groups, and devices. Create, update, and revoke actions are unavailable.",
  ),
  "MCODE-00213": AppMessage(ja: "編集者ビュー", en: "Editor view"),
  "MCODE-00214": AppMessage(
    ja: "デバイスの失効とグループへのデバイス割当が可能です。グループの作成・削除やロール付与は管理者のみ表示されます。",
    en: "Can revoke devices and assign devices to groups. Only administrators can manage groups and roles.",
  ),
  "MCODE-00215": AppMessage(ja: "名前", en: "Name"),
  "MCODE-00216": AppMessage(ja: "プロジェクトロール", en: "Project roles"),
  "MCODE-00217": AppMessage(ja: "グループロール", en: "Group roles"),
  "MCODE-00218": AppMessage(ja: "作成", en: "Create"),
  "MCODE-00219": AppMessage(ja: "付与", en: "Assign"),
  "MCODE-00220": AppMessage(ja: "失効", en: "Revoke"),
  "MCODE-00221": AppMessage(
    ja: "管理者: グループ作成・プロジェクト/グループのロール付与・デバイス失効が可能です。",
    en: "Admin: can create groups, assign project/group roles, and revoke devices.",
  ),
  "MCODE-00222": AppMessage(
    ja: "編集者: デバイス失効とグループへのデバイス割当が可能です。グループ作成とロール付与は管理者のみです。",
    en: "Editor: can revoke devices and assign them to groups. Only admins can create groups or assign roles.",
  ),
  "MCODE-00223": AppMessage(
    ja: "閲覧者: 参照のみ可能です。変更操作は表示されません。",
    en: "Viewer: read-only access.",
  ),
  "MCODE-00224": AppMessage(
    ja: "このグループのロールがありません。",
    en: "No role is assigned for this group.",
  ),
  "MCODE-00225": AppMessage(ja: "グループ情報", en: "Group information"),
  "MCODE-00226": AppMessage(ja: "作成日時", en: "Created"),
  "MCODE-00227": AppMessage(ja: "更新日時", en: "Updated"),
  "MCODE-00228": AppMessage(ja: "グループデバイス", en: "Group devices"),
  "MCODE-00229": AppMessage(ja: "追加", en: "Add"),
  "MCODE-00230": AppMessage(
    ja: "デバイスが割り当てられていません。",
    en: "No devices are assigned.",
  ),
  "MCODE-00231": AppMessage(
    ja: "デバイスが割り当てられていません。右上の「追加」から割り当てできます。",
    en: "No devices are assigned. Use Add to assign one.",
  ),
  "MCODE-00232": AppMessage(ja: "グループから外す", en: "Remove from group"),
  "MCODE-00233": AppMessage(ja: "グループを編集", en: "Edit group"),
  "MCODE-00234": AppMessage(ja: "グループを削除", en: "Delete group"),
  "MCODE-00235": AppMessage(ja: "グループを削除しますか？", en: "Delete this group?"),
  "MCODE-00236": AppMessage(ja: "グループを作成", en: "Create group"),
  "MCODE-00237": AppMessage(
    ja: "小文字英数字とハイフン（例: engineering）",
    en: "Lowercase letters, numbers, and hyphens (e.g. engineering)",
  ),
  "MCODE-00238": AppMessage(ja: "表示名を入力してください。", en: "Enter a display name."),
  "MCODE-00239": AppMessage(
    ja: "Slugは小文字英数字とハイフンで入力してください。",
    en: "Use lowercase letters, numbers, and hyphens for the slug.",
  ),
  "MCODE-00240": AppMessage(ja: "削除する", en: "Delete"),
  "MCODE-00241": AppMessage(ja: "グループを更新しました。", en: "Group updated."),
  "MCODE-00242": AppMessage(ja: "グループロールを付与", en: "Assign group role"),
  "MCODE-00243": AppMessage(
    ja: "自分のロールは変更できません。最後のプロジェクト管理者も削除できません。",
    en: "You cannot change your own role or remove the last project administrator.",
  ),
  "MCODE-00244": AppMessage(
    ja: "OIDC Subjectを入力してください。",
    en: "Enter the OIDC subject.",
  ),
  "MCODE-00245": AppMessage(ja: "OIDC Subject", en: "OIDC subject"),
  "MCODE-00246": AppMessage(
    ja: "Keycloakのsub（ユーザーのUUID）",
    en: "Keycloak sub (user UUID)",
  ),
  "MCODE-00247": AppMessage(ja: "ロール", en: "Role"),
  "MCODE-00248": AppMessage(ja: "グループにデバイスを追加", en: "Add device to group"),
  "MCODE-00249": AppMessage(
    ja: "追加できるデバイスがありません。",
    en: "No devices are available to add.",
  ),
  "MCODE-00250": AppMessage(ja: "グループロールがありません。", en: "No group roles."),
  "MCODE-00251": AppMessage(ja: "プロジェクトロールがありません。", en: "No project roles."),
  "MCODE-00252": AppMessage(ja: "グループロールを付与しました。", en: "Group role assigned."),
  "MCODE-00253": AppMessage(ja: "グループロールを削除しました。", en: "Group role removed."),
  "MCODE-00254": AppMessage(
    ja: "プロジェクトロールを付与しました。",
    en: "Project role assigned.",
  ),
  "MCODE-00255": AppMessage(
    ja: "プロジェクトロールを削除しました。",
    en: "Project role removed.",
  ),
  "MCODE-00256": AppMessage(
    ja: "グループを削除します。元に戻せません。",
    en: "Delete this group? This cannot be undone.",
  ),
  "MCODE-00257": AppMessage(ja: "グループを作成しました。", en: "Group created."),
  "MCODE-00258": AppMessage(
    ja: "デバイスをグループに追加しました。",
    en: "Device added to group.",
  ),
  "MCODE-00259": AppMessage(
    ja: "デバイスをグループから外しました。",
    en: "Device removed from group.",
  ),
  "MCODE-00260": AppMessage(
    ja: "追加できるデバイスがありません。デバイスタブで登録してください。",
    en: "No devices are available. Register a device first.",
  ),
  "MCODE-00261": AppMessage(ja: "閲覧者ビュー", en: "Viewer view"),
  "MCODE-00262": AppMessage(
    ja: "管理者: グループの編集・削除、デバイス割当、グループロール付与が可能です。",
    en: "Admin: can edit/delete groups, assign devices, and grant group roles.",
  ),
  "MCODE-00263": AppMessage(
    ja: "編集者: グループへのデバイス追加・削除が可能です。ロール付与は管理者のみです。",
    en: "Editor: can add/remove group devices. Only admins can assign roles.",
  ),
  "MCODE-00264": AppMessage(
    ja: "閲覧者: グループ内のデバイスを参照できます。",
    en: "Viewer: can view devices in the group.",
  ),
  "MCODE-00265": AppMessage(ja: "対応状況を読み込み中...", en: "Loading support status…"),
  "MCODE-00266": AppMessage(ja: "Keycloak Realm", en: "Keycloak realm"),
  "MCODE-00267": AppMessage(ja: "Project ID", en: "Project ID"),
  "MCODE-00268": AppMessage(ja: "Slug", en: "Slug"),
  "MCODE-00269": AppMessage(ja: "Gorapeプロジェクトがありません", en: "No Gorape project"),
  "MCODE-00270": AppMessage(
    ja: "プロジェクトがまだ作成されていません。",
    en: "No projects have been created yet.",
  ),
  "MCODE-00271": AppMessage(
    ja: "このプラットフォームではOIDCを利用できません。",
    en: "OIDC is unavailable on this platform.",
  ),
  "MCODE-00272": AppMessage(ja: "ロールを付与", en: "Assign role"),
  "MCODE-00273": AppMessage(ja: "デバイス名を入力してください。", en: "Enter a device name."),
  "MCODE-00274": AppMessage(
    ja: "このOSではOS保護鍵を生成できません。",
    en: "Protected keys cannot be generated on this OS.",
  ),
  "MCODE-00275": AppMessage(
    ja: "登録チャレンジの有効期限が切れています。もう一度お試しください。",
    en: "The registration challenge expired. Please try again.",
  ),
  "MCODE-00276": AppMessage(
    ja: "署名チャレンジの有効期限が切れています。もう一度お試しください。",
    en: "The signing challenge expired. Please try again.",
  ),
  "MCODE-00277": AppMessage(
    ja: "この端末には該当デバイスの秘密鍵がありません。",
    en: "The private key for this device is not on this device.",
  ),
  "MCODE-00278": AppMessage(
    ja: "別の端末で登録されたデバイスは署名できません。この端末で登録し直してください。",
    en: "Devices registered on another device cannot sign here. Register this device again.",
  ),
  "MCODE-00279": AppMessage(
    ja: "端末の画面ロック設定とKeystoreの状態を確認してください。",
    en: "Check the screen-lock settings and Keystore status.",
  ),
  "MCODE-00280": AppMessage(
    ja: "端末のロック解除状態を確認するか、デバイスを再登録してください。",
    en: "Unlock the device or register it again.",
  ),
  "MCODE-00281": AppMessage(
    ja: "Keycloakからアクセストークンが返されませんでした。",
    en: "Keycloak did not return an access token.",
  ),
  "MCODE-00282": AppMessage(
    ja: "ログインセッションがありません。もう一度ログインしてください。",
    en: "No sign-in session. Please sign in again.",
  ),
  "MCODE-00283": AppMessage(
    ja: "セッションを更新できません。もう一度ログインしてください。",
    en: "Could not refresh the session. Please sign in again.",
  ),
  "MCODE-00284": AppMessage(
    ja: "セッションの更新に失敗しました。もう一度ログインしてください。",
    en: "Session refresh failed. Please sign in again.",
  ),
  "MCODE-00285": AppMessage(
    ja: "Gorape APIへの接続がタイムアウトしました。",
    en: "The connection to the Gorape API timed out.",
  ),
  "MCODE-00286": AppMessage(
    ja: "Gorape APIへ接続できませんでした。",
    en: "Could not connect to the Gorape API.",
  ),
  "MCODE-00287": AppMessage(
    ja: "アクセストークンの有効期限、Issuer、Audience（gorape-api）を確認してください。初回起動時は、このIssuerのGorapeプロジェクトがbootstrap済みかも確認してください。",
    en: "Check the access token expiry, issuer, and audience (gorape-api). On first launch, ensure a Gorape project is bootstrapped for this issuer.",
  ),
  "MCODE-00288": AppMessage(
    ja: "アクセストークンの有効期限、Issuer、Audience（gorape-api）を確認してください。",
    en: "Check the access token expiry, issuer, and audience (gorape-api).",
  ),
  "MCODE-00289": AppMessage(
    ja: "Keycloakログインに失敗しました。",
    en: "Keycloak sign-in failed.",
  ),
  "MCODE-00290": AppMessage(
    ja: "API URLとDocker環境を確認してください。",
    en: "Check the API URL and Docker environment.",
  ),
  "MCODE-00291": AppMessage(
    ja: "OS保護鍵を利用できません",
    en: "Protected key unavailable",
  ),
  "MCODE-00292": AppMessage(
    ja: "Attestationが未設定です",
    en: "Attestation is not configured",
  ),
  "MCODE-00293": AppMessage(
    ja: "現行バックエンドではAndroid Key Attestationのみ実装されています。",
    en: "The current backend only implements Android Key Attestation.",
  ),
  "MCODE-00294": AppMessage(
    ja: "Android verifierは",
    en: "The Android verifier is ",
  ),
  "MCODE-00295": AppMessage(
    ja: "GorapeのAndroid Attestation検証が未設定です。",
    en: "Android attestation verification is not configured in Gorape.",
  ),
  "MCODE-00296": AppMessage(
    ja: "バックエンドの android_trust_anchors が空の場合、capabilitiesは unconfiguredを返し、登録は422で失敗します。",
    en: "If backend android_trust_anchors is empty, capabilities reports unconfigured and registration fails with 422.",
  ),
  "MCODE-00297": AppMessage(
    ja: "Gorapeの Application.Server.Attestation.android_trust_anchors にGoogleのKey Attestation Root CAを設定し、capabilitiesが implementedを返すことを確認してください。",
    en: "Configure Google Key Attestation Root CA in Application.Server.Attestation.android_trust_anchors and verify capabilities reports implemented.",
  ),
  "MCODE-00298": AppMessage(
    ja: "Gorape APIへは送信されません（ポリシーAPIがないため）。",
    en: "Not sent to Gorape (no policy API is available).",
  ),
  "MCODE-00299": AppMessage(
    ja: "デバイスポリシーAPIを追加してから接続してください。",
    en: "Add a device policy API before connecting.",
  ),
  "MCODE-00300": AppMessage(
    ja: "表示はKeycloakトークンのロールを反映し、API認可はGorape側でDBロール付与とKeycloakロールを用いて判定されます。",
    en: "The UI reflects Keycloak token roles; the API resolves authorization using Gorape role bindings and Keycloak roles.",
  ),
  "MCODE-00301": AppMessage(
    ja: "初回起動時は、このIssuerのGorapeプロジェクトがbootstrap済みかも確認してください。",
    en: "On first launch, verify that a Gorape project has been bootstrapped for this issuer.",
  ),
  "MCODE-00302": AppMessage(
    ja: "Android実機ではAndroid KeystoreにEC P-256鍵を生成し、",
    en: "On a physical Android device, generate an EC P-256 key in Android Keystore and ",
  ),
  "MCODE-00303": AppMessage(
    ja: "Attestation対象外です。Windows/Linux/Webでは",
    en: "Attestation is unavailable. On Windows/Linux/Web, ",
  ),
  "MCODE-00304": AppMessage(
    ja: "Base64urlを生バイト列へデコード",
    en: "Decode Base64url into raw bytes",
  ),
  "MCODE-00305": AppMessage(
    ja: "EC P-256公開鍵と証明書チェーン（leaf-first）を送信",
    en: "Send the EC P-256 public key and certificate chain (leaf first)",
  ),
  "MCODE-00306": AppMessage(
    ja: "Gorapeに登録したOS保護鍵で所有証明を行います。",
    en: "Prove possession using the OS-protected key registered with Gorape.",
  ),
  "MCODE-00307": AppMessage(
    ja: "Gorapeのデバイス鍵による所有証明とは別物です。",
    en: "This is separate from proof of possession using a Gorape device key.",
  ),
  "MCODE-00308": AppMessage(
    ja: "Gorapeの実認可はDBロール付与とKeycloakクレームを併用して行われます。",
    en: "Gorape authorization combines database role bindings with Keycloak claims.",
  ),
  "MCODE-00309": AppMessage(
    ja: "GorapeはGoogle Hardware Attestation Root CAまでの",
    en: "Gorape verifies the chain up to the Google Hardware Attestation Root CA ",
  ),
  "MCODE-00310": AppMessage(
    ja: "Gorapeバックエンドでは強制されません。",
    en: "is not enforced by the Gorape backend.",
  ),
  "MCODE-00311": AppMessage(
    ja: "Gorapeバックエンドのverifierが",
    en: "the Gorape backend verifier ",
  ),
  "MCODE-00312": AppMessage(
    ja: "Gorapeリポジトリのgorape-adminでプロジェクトを",
    en: "Bootstrap a project with gorape-admin in the Gorape repository and ",
  ),
  "MCODE-00313": AppMessage(
    ja: "Gorape側でeditor権限があっても、UIからは登録できません。",
    en: "Registration is unavailable in the UI even if Gorape grants editor permissions.",
  ),
  "MCODE-00314": AppMessage(
    ja: "Gorape側でデバイスがrevokedになります。",
    en: "The device will be revoked in Gorape.",
  ),
  "MCODE-00315": AppMessage(
    ja: "Key Attestation証明書チェーンをGorapeへ送信します。",
    en: "Send the Key Attestation certificate chain to Gorape.",
  ),
  "MCODE-00316": AppMessage(
    ja: "Key Attestation証明書チェーン（leaf-first）を取得します。",
    en: "Retrieve the Key Attestation certificate chain (leaf first).",
  ),
  "MCODE-00317": AppMessage(
    ja: "KeyGenParameterSpec.setAttestationChallenge に同じバイト列を設定",
    en: "Set the same bytes with KeyGenParameterSpec.setAttestationChallenge",
  ),
  "MCODE-00318": AppMessage(
    ja: "Keycloakでrealmロール admin が付与されています。",
    en: "The Keycloak realm role admin is assigned.",
  ),
  "MCODE-00319": AppMessage(
    ja: "Keycloakでサインインし、OS保護鍵をGorapeに登録します。",
    en: "Sign in with Keycloak and register an OS-protected key with Gorape.",
  ),
  "MCODE-00320": AppMessage(
    ja: "Keycloakでユーザーにrealmロール admin / editor / viewer を付与するか、",
    en: "Assign the user the Keycloak realm role admin/editor/viewer, or ",
  ),
  "MCODE-00321": AppMessage(
    ja: "Keycloakの gorape-client に以下を登録してください。",
    en: "Add the following to the Keycloak gorape-client.",
  ),
  "MCODE-00322": AppMessage(
    ja: "Keycloakのパスキーとは独立しています。",
    en: "This is independent of Keycloak passkeys.",
  ),
  "MCODE-00323": AppMessage(
    ja: "KeycloakクライアントのGroup Membership mapperを有効にすると表示されます。",
    en: "Shown when the Group Membership mapper is enabled for the Keycloak client.",
  ),
  "MCODE-00324": AppMessage(
    ja: "Keycloakトークンにこのスコープのロールが含まれていません。",
    en: "The Keycloak token has no role for this scope.",
  ),
  "MCODE-00325": AppMessage(
    ja: "Keycloakトークンにこのプロジェクトのロールがありません。",
    en: "The Keycloak token has no role for this project.",
  ),
  "MCODE-00326": AppMessage(
    ja: "Keycloakトークンのロールから表示を切り替えています。",
    en: "The view is selected from roles in the Keycloak token.",
  ),
  "MCODE-00327": AppMessage(
    ja: "KeycloakユーザーがGorapeのProjectロールを持っていないか、",
    en: "The Keycloak user may not have a Gorape project role, or ",
  ),
  "MCODE-00328": AppMessage(
    ja: "Keycloakログインはflutter_appauthで対応します。",
    en: "Keycloak sign-in uses flutter_appauth.",
  ),
  "MCODE-00329": AppMessage(
    ja: "Keycloakログイン後にチャレンジ署名を促すUIを表示します。",
    en: "Show a prompt to sign a challenge after Keycloak sign-in.",
  ),
  "MCODE-00330": AppMessage(
    ja: "OIDC IssuerはKeycloakが発行する iss クレームと完全に一致する必要があります。",
    en: "The OIDC issuer must exactly match the iss claim issued by Keycloak.",
  ),
  "MCODE-00331": AppMessage(
    ja: "OS保護鍵で署名します。ECDSAはASN.1 DER、",
    en: "Sign with the OS-protected key. ECDSA uses ASN.1 DER; ",
  ),
  "MCODE-00332": AppMessage(
    ja: "POST /devices/registration/challenge で単一使用チャレンジを取得",
    en: "Request a single-use challenge with POST /devices/registration/challenge",
  ),
  "MCODE-00333": AppMessage(
    ja: "POST /devices/registration/verify が422なら信頼アンカーを確認",
    en: "If POST /devices/registration/verify returns 422, check the trust anchors",
  ),
  "MCODE-00334": AppMessage(
    ja: "RSAはPKCS#1 v1.5/SHA-256、Ed25519は生バイト列です。",
    en: "RSA uses PKCS#1 v1.5/SHA-256; Ed25519 signs raw bytes.",
  ),
  "MCODE-00335": AppMessage(
    ja: "Windows TPM、Linux、Webは現行のGorapeバックエンドで",
    en: "Windows TPM, Linux, and Web are ",
  ),
  "MCODE-00336": AppMessage(ja: "を実行してください。", en: " run this command."),
  "MCODE-00337": AppMessage(
    ja: "adb reverse を使う場合は localhost:8000 も利用できます。",
    en: "With adb reverse, localhost:8000 can also be used.",
  ),
  "MCODE-00338": AppMessage(
    ja: "android_trust_anchors にGoogle Hardware Attestation Root CAを",
    en: "Add the Google Hardware Attestation Root CA to android_trust_anchors and ",
  ),
  "MCODE-00339": AppMessage(
    ja: "audience: gorape-api。Gorape APIにはAccess Tokenのみを使用し、",
    en: "audience: gorape-api. Only the access token is sent to the Gorape API; ",
  ),
  "MCODE-00340": AppMessage(
    ja: "flutter_appauthによるOIDCログインも未対応のため、",
    en: "OIDC sign-in with flutter_appauth is also unsupported, so ",
  ),
  "MCODE-00341": AppMessage(
    ja: "gorape_*属性がトークンに含まれていません。",
    en: "gorape_* attributes are not present in the token.",
  ),
  "MCODE-00342": AppMessage(
    ja: "gorape_project_role / gorape_group_<slug>_role 属性を",
    en: "Map the gorape_project_role / gorape_group_<slug>_role attributes ",
  ),
  "MCODE-00343": AppMessage(
    ja: "gorape_project_role / gorape_group_<slug>_role 属性をアクセストークンへマッピングしてください。",
    en: "Map gorape_project_role / gorape_group_<slug>_role attributes into the access token.",
  ),
  "MCODE-00344": AppMessage(
    ja: "iOS/macOS/AndroidのみKeycloakログインを提供します。",
    en: "Keycloak sign-in is available only on iOS/macOS/Android.",
  ),
  "MCODE-00345": AppMessage(
    ja: "realmロール admin / editor / viewer、または",
    en: "realm role admin/editor/viewer, or ",
  ),
  "MCODE-00346": AppMessage(
    ja: "redirectUris に追加します。詳細は README を参照してください。",
    en: "Add these to redirectUris. See the README for details.",
  ),
  "MCODE-00347": AppMessage(
    ja: "サーバーのチャレンジをKeyGenParameterSpecへバインドして",
    en: "Bind the server challenge to KeyGenParameterSpec and ",
  ),
  "MCODE-00348": AppMessage(
    ja: "サーバーのチャレンジをOS鍵生成にバインドし、公開鍵と",
    en: "Bind the server challenge to OS key generation and submit the public key and ",
  ),
  "MCODE-00349": AppMessage(
    ja: "チェーンを検証します。",
    en: "Verify the certificate chain.",
  ),
  "MCODE-00350": AppMessage(
    ja: "デバイスの失効とグループへのデバイス割当が可能です。",
    en: "Can revoke devices and assign devices to groups.",
  ),
  "MCODE-00351": AppMessage(
    ja: "デバイス秘密鍵はOSキーストアから出ません。",
    en: "Device private keys never leave the OS keystore.",
  ),
  "MCODE-00352": AppMessage(
    ja: "バックエンドがAttestationをverifiedとして記録しました。",
    en: "The backend recorded the attestation as verified.",
  ),
  "MCODE-00353": AppMessage(
    ja: "バックエンドの android_trust_anchors が空の場合、",
    en: "If backend android_trust_anchors is empty, ",
  ),
  "MCODE-00354": AppMessage(
    ja: "バックエンドの登録APIはAttestation証拠を要求します。",
    en: "The backend registration API requires attestation evidence.",
  ),
  "MCODE-00355": AppMessage(
    ja: "バックエンド側のVerifier追加が必要です。",
    en: "A backend verifier must be added.",
  ),
  "MCODE-00356": AppMessage(
    ja: "パスキーとMFAはKeycloak、デバイス検証はGorapeが担当します。",
    en: "Keycloak handles passkeys and MFA; Gorape handles device verification.",
  ),
  "MCODE-00357": AppMessage(
    ja: "パスキーとデバイス鍵の役割",
    en: "How passkeys and device keys differ",
  ),
  "MCODE-00358": AppMessage(
    ja: "パスキーはKeycloakアカウントに紐づき、複数端末で共有されます。",
    en: "Passkeys belong to the Keycloak account and can be shared across devices.",
  ),
  "MCODE-00359": AppMessage(
    ja: "パスキー・MFA・アカウント回復はKeycloakの責務です。",
    en: "Keycloak handles passkeys, MFA, and account recovery.",
  ),
  "MCODE-00360": AppMessage(
    ja: "プロジェクト/グループ固有のロールはrealmロールへフォールバックします。",
    en: "Project/group-specific roles fall back to the realm role.",
  ),
  "MCODE-00361": AppMessage(ja: "プロジェクトのグループ", en: "Project groups"),
  "MCODE-00362": AppMessage(ja: "プロジェクトを切り替え", en: "Switch project"),
  "MCODE-00363": AppMessage(ja: "プロジェクト一覧", en: "Project list"),
  "MCODE-00364": AppMessage(
    ja: "ログアウトするとKeycloakのセッション終了を試行し、",
    en: "Signing out attempts to end the Keycloak session and ",
  ),
  "MCODE-00365": AppMessage(
    ja: "ログイン画面で明示的に案内します。",
    en: "shown explicitly on the sign-in screen.",
  ),
  "MCODE-00366": AppMessage(
    ja: "ローカルのトークンを削除します。",
    en: "removes local tokens.",
  ),
  "MCODE-00367": AppMessage(
    ja: "ロールを変えると、この画面は管理者・編集者・閲覧者のいずれかに切り替わります。",
    en: "Changing roles switches this screen between administrator, editor, and viewer views.",
  ),
  "MCODE-00368": AppMessage(
    ja: "他端末で登録されたデバイスは表示・失効のみ可能です。",
    en: "Devices registered on another device can only be viewed or revoked.",
  ),
  "MCODE-00369": AppMessage(
    ja: "参照はGorape側の権限に従いますが、登録・失効などの変更操作は無効です。",
    en: "Viewing follows Gorape permissions, but registration and revocation are disabled.",
  ),
  "MCODE-00370": AppMessage(
    ja: "参照はできますが、所有証明・失効は実行できません。",
    en: "Can view, but cannot prove possession or revoke devices.",
  ),
  "MCODE-00371": AppMessage(
    ja: "各グループのロールは、プロジェクトロールとKeycloakのグループ別ロールの",
    en: "Each group role is resolved from the project role and Keycloak group role; ",
  ),
  "MCODE-00372": AppMessage(
    ja: "有効ロールはプロジェクトロールとKeycloakのグループ別ロールから解決され、API側で再認可されます。",
    en: "The effective role combines project and Keycloak group roles; the API independently authorizes each request.",
  ),
  "MCODE-00373": AppMessage(
    ja: "実際の作成・変更権限はGorapeのproject/groupロール付与に従います。",
    en: "Actual create/update permissions follow Gorape project/group role bindings.",
  ),
  "MCODE-00374": AppMessage(
    ja: "強い方で表示されます（Gorapeのeffective roleと同じ考え方）。",
    en: "the stronger role is shown, matching Gorape effective-role resolution.",
  ),
  "MCODE-00375": AppMessage(
    ja: "所有証明ではBase64urlチャレンジを生バイト列に戻し、",
    en: "For proof of possession, decode the Base64url challenge to raw bytes and ",
  ),
  "MCODE-00376": AppMessage(
    ja: "既存CLI用の http://127.0.0.1:8400/callback は変更・削除しません。",
    en: "The existing CLI callback http://127.0.0.1:8400/callback is preserved.",
  ),
  "MCODE-00377": AppMessage(
    ja: "有効ロールはプロジェクトロールとグループロールの強い方です。",
    en: "The effective role is the stronger of the project and group roles.",
  ),
  "MCODE-00378": AppMessage(
    ja: "権限はログインするKeycloakアカウントで決まります。",
    en: "Permissions are determined by the signed-in Keycloak account.",
  ),
  "MCODE-00379": AppMessage(
    ja: "正規のRedirect URIを使用してください。",
    en: "Use a registered redirect URI.",
  ),
  "MCODE-00380": AppMessage(
    ja: "登録後、チャレンジ署名による所有証明を実行できます。",
    en: "After registration, prove possession by signing a challenge.",
  ),
  "MCODE-00381": AppMessage(
    ja: "管理者: グループの作成・編集・削除、グループロールの付与が可能です。",
    en: "Admin: can create/edit/delete groups and grant group roles.",
  ),
  "MCODE-00382": AppMessage(
    ja: "管理者または編集者のロールが必要です。",
    en: "An administrator or editor role is required.",
  ),
  "MCODE-00383": AppMessage(
    ja: "続けてチャレンジ署名による所有証明を実行できます。",
    en: "You can then prove possession by signing a challenge.",
  ),
  "MCODE-00384": AppMessage(
    ja: "編集者: グループ内のデバイス割当を変更できます。グループ自体の作成・削除は管理者のみです。",
    en: "Editor: can change group device assignments. Only admins can create or delete groups.",
  ),
  "MCODE-00385": AppMessage(
    ja: "編集者: デバイス失効とグループへのデバイス割当が可能です。",
    en: "Editor: can revoke devices and assign devices to groups.",
  ),
  "MCODE-00386": AppMessage(
    ja: "行いません。App AttestやSecure Enclaveを利用するには",
    en: "is not performed. To use App Attest or Secure Enclave, ",
  ),
  "MCODE-00387": AppMessage(
    ja: "設定するまで登録は失敗します。",
    en: "Registration will fail until configured.",
  ),
  "MCODE-00388": AppMessage(
    ja: "証明書チェーン（leaf-first）",
    en: "Certificate chain (leaf first)",
  ),
  "MCODE-00389": AppMessage(
    ja: "閲覧者: グループとデバイスを参照できます。",
    en: "Viewer: can view groups and devices.",
  ),
  "MCODE-00390": AppMessage(ja: "Attestation証拠", en: "Attestation evidence"),
  "MCODE-00391": AppMessage(
    ja: "このスコープではデバイスを登録できません。",
    en: "Device registration is unavailable in this scope.",
  ),
  "MCODE-00392": AppMessage(
    ja: "このスコープのロールがありません。",
    en: "No role is assigned for this scope.",
  ),
  "MCODE-00393": AppMessage(
    ja: "このビルドでは取得できません",
    en: "Unavailable in this build",
  ),
  "MCODE-00394": AppMessage(
    ja: "この画面の値は端末内に保存される希望値です。",
    en: "These are preferences stored on this device.",
  ),
  "MCODE-00395": AppMessage(
    ja: "この設定は表示上の希望値であり、登録可否を変えません。",
    en: "This preference is informational and does not affect registration eligibility.",
  ),
  "MCODE-00396": AppMessage(
    ja: "このアプリはパスキーの秘密情報を保存せず、",
    en: "This app does not store passkey secrets; ",
  ),
  "MCODE-00397": AppMessage(
    ja: "ただしGorapeのAttestation VerifierはiOS/macOSを",
    en: "However, the Gorape Attestation Verifier does not support iOS/macOS ",
  ),
  "MCODE-00398": AppMessage(
    ja: "グループの作成・削除やロール付与は管理者のみ表示されます。",
    en: "Only administrators can create/delete groups or assign roles.",
  ),
  "MCODE-00399": AppMessage(
    ja: "グループへのデバイス追加・削除が可能です。グループ編集・削除とロール付与は管理者のみです。",
    en: "Can add/remove devices in groups. Only administrators can edit/delete groups or assign roles.",
  ),
  "MCODE-00400": AppMessage(
    ja: "グループ作成とロール付与は管理者のみです。",
    en: "Only administrators can create groups and assign roles.",
  ),
  "MCODE-00401": AppMessage(
    ja: "グループ情報と割り当てデバイスを参照できます。追加・削除は表示されません。",
    en: "Can view group information and assigned devices. Add/remove actions are unavailable.",
  ),
  "MCODE-00402": AppMessage(ja: "ステータス", en: "Status"),
  "MCODE-00403": AppMessage(ja: "ソフトウェア", en: "Software"),
  "MCODE-00404": AppMessage(ja: "デバイスを登録", en: "Register device"),
  "MCODE-00405": AppMessage(ja: "デバイスポリシー", en: "Device policy"),
  "MCODE-00406": AppMessage(ja: "ハードウェア", en: "Hardware"),
  "MCODE-00407": AppMessage(
    ja: "ローカルKeycloakの例: admin CLIで clients/gorape-client の",
    en: "Local Keycloak example: use the admin CLI to update clients/gorape-client ",
  ),
  "MCODE-00408": AppMessage(
    ja: "別のユーザーを使う場合は、ログアウトしてから再ログインしてください。",
    en: "To switch users, sign out and sign in again.",
  ),
  "MCODE-00409": AppMessage(
    ja: "変更後は再ログイン（またはトークン更新）で反映されます。",
    en: "Sign in again or refresh the token for changes to take effect.",
  ),
  "MCODE-00410": AppMessage(ja: "接続設定を開く", en: "Open connection settings"),
  "MCODE-00411": AppMessage(
    ja: "「Gorape」はバックエンドのVerifier対応状況です。",
    en: "“Gorape” shows backend verifier support.",
  ),
  "MCODE-00412": AppMessage(
    ja: "「アプリ側」はFlutterクライアントの実装状況、",
    en: "“App” shows Flutter client implementation status; ",
  ),
  "MCODE-00413": AppMessage(
    ja: "「管理」タブではKeycloakトークンのロールとグループを確認できます。",
    en: "Check Keycloak token roles and groups in the Management tab.",
  ),
  "MCODE-00414": AppMessage(
    ja: "クラスタ全体のロール確認に加えて、各プロジェクトの管理画面へ移動できます。",
    en: "Review cluster roles and open each project management view.",
  ),
  "MCODE-00415": AppMessage(
    ja: "Gorape APIにはアクセストークンのみを送信します。",
    en: "Only the access token is sent to the Gorape API.",
  ),
  "MCODE-00416": AppMessage(
    ja: "Access TokenのみをGorape APIへ送信します。ID TokenはAPI認証情報として使用しません。",
    en: "Only the access token is sent to the Gorape API; the ID token is never used for API authentication.",
  ),
  "MCODE-00417": AppMessage(
    ja: "Access TokenはGorape APIのBearer認証にのみ使用します。",
    en: "The access token is only used as a Gorape API bearer credential.",
  ),
  "MCODE-00418": AppMessage(
    ja: "ID Tokenは送信しません。",
    en: "The ID token is not sent.",
  ),
  "MCODE-00419": AppMessage(
    ja: "APIは既定で 10.0.2.2:8000 を利用します。",
    en: "The API defaults to 10.0.2.2:8000.",
  ),
  "MCODE-00420": AppMessage(
    ja: "Android Emulatorは 10.0.2.2、実機はPCのLAN IPを指定してください。",
    en: "Use 10.0.2.2 for Android emulators and your PC LAN IP for physical devices.",
  ),
  "MCODE-00421": AppMessage(
    ja: "Android Emulatorでは OIDC 用に",
    en: "For OIDC on Android emulators, ",
  ),
  "MCODE-00422": AppMessage(
    ja: "`adb reverse tcp:8080 tcp:8080` を実行してください。",
    en: "run `adb reverse tcp:8080 tcp:8080`.",
  ),
  "MCODE-00423": AppMessage(ja: "保存に失敗しました: ", en: "Save failed: "),
  "MCODE-00424": AppMessage(
    ja: "Android実機でOS保護鍵を生成し、Gorapeへ登録してください。",
    en: "Generate an OS-protected key on a physical Android device and register it with Gorape.",
  ),
  "MCODE-00425": AppMessage(ja: "{{count}} 台", en: "{{count}} devices"),
  "MCODE-00426": AppMessage(ja: "{{count}} 件", en: "{{count}} items"),
  "MCODE-00427": AppMessage(
    ja: "ほか {{count}} 台（デバイスタブで確認）",
    en: "{{count}} more (see Devices tab)",
  ),
  "MCODE-00428": AppMessage(ja: "プロジェクト「{{name}}」", en: "Project “{{name}}”"),
  "MCODE-00429": AppMessage(ja: "グループ「{{name}}」", en: "Group “{{name}}”"),
  "MCODE-00430": AppMessage(
    ja: "プロジェクト「{{name}}」のロール",
    en: "Project “{{name}}” role",
  ),
  "MCODE-00431": AppMessage(
    ja: "グループ「{{name}}」のロール",
    en: "Group “{{name}}” role",
  ),
  "MCODE-00432": AppMessage(
    ja: "グループ「{{name}}」を作成しました。",
    en: "Group “{{name}}” created.",
  ),
  "MCODE-00433": AppMessage(
    ja: "「{{name}}」を削除します。元に戻せません。",
    en: "Delete “{{name}}”? This cannot be undone.",
  ),
  "MCODE-00434": AppMessage(
    ja: "{{name}} をGorape側でrevokedにします。元に戻せません。",
    en: "Revoke {{name}} in Gorape? This cannot be undone.",
  ),
  "MCODE-00435": AppMessage(
    ja: "保存に失敗しました: {{message}}",
    en: "Could not save: {{message}}",
  ),
  "MCODE-00436": AppMessage(ja: "応答: {{message}}", en: "Response: {{message}}"),
  "MCODE-00437": AppMessage(
    ja: "この端末: {{name}}。Keycloakログインはflutter_appauthで対応します。",
    en: "This device: {{name}}. Keycloak sign-in uses flutter_appauth.",
  ),
  "MCODE-00438": AppMessage(ja: "{{scope}}のロール", en: "{{scope}} role"),
  "MCODE-00439": AppMessage(
    ja: "{{scope}}のロールがありません",
    en: "No role is assigned for {{scope}}",
  ),
  "MCODE-00440": AppMessage(
    ja: "{{name}} をグループから外しました。",
    en: "{{name}} removed from the group.",
  ),
  "MCODE-00441": AppMessage(ja: "パスキー端末を登録", en: "Register passkey device"),
  "MCODE-00442": AppMessage(
    ja: "パスキーassertionで所有証明",
    en: "Prove possession with a passkey assertion",
  ),
  "MCODE-00443": AppMessage(
    ja: "パスキーassertionをGorapeが検証しました。",
    en: "Gorape verified the passkey assertion.",
  ),
  "MCODE-00444": AppMessage(
    ja: "すべて表示（{{count}} 件）",
    en: "Show all ({{count}} items)",
  ),
  "MCODE-00445": AppMessage(
    ja: "Attestationなしの登録を希望（参考値）",
    en: "Prefer registration without attestation (informational)",
  ),
  "MCODE-00446": AppMessage(ja: "Keycloak OIDC", en: "Keycloak OIDC"),
  "MCODE-00447": AppMessage(ja: "Gorape passkey", en: "Gorape passkey"),
  "MCODE-00448": AppMessage(ja: "Legacy key", en: "Legacy key"),
  "MCODE-00449": AppMessage(ja: "Legacy attestation", en: "Legacy attestation"),
  "MCODE-00450": AppMessage(ja: "Legacy verifier", en: "Legacy verifier"),
  "MCODE-00451": AppMessage(ja: "active", en: "Active"),
  "MCODE-00452": AppMessage(ja: "inactive", en: "Inactive"),
  "MCODE-00453": AppMessage(ja: "English", en: "English"),
  "MCODE-00454": AppMessage(
    ja: "Keycloakログイン後にGorape passkey assertionを促すUIを表示します。（アプリ内の案内のみ）",
    en: "Show an in-app prompt to prove possession with a Gorape passkey assertion after Keycloak sign-in. This is guidance only.",
  ),
  "MCODE-00455": AppMessage(
    ja: "登録可否はGorapeの設定ファイルが決定します。既定ではnoneを拒否し、この端末内の値はAPIへ送信されず、サーバーpolicyを変更しません。",
    en: "Gorape configuration controls registration. The default rejects none attestation; this local preference is not sent to the API and does not change server policy.",
  ),
  "MCODE-00456": AppMessage(
    ja: "新しいdevice登録はGorape RP用WebAuthn passkeyを使います。Keycloak passkeyとは別credentialです。秘密鍵はOS/providerに残り、同期可否はproviderが管理します。端末内のlegacy passkey strategy設定は登録方式やサーバーpolicyを変更しません。",
    en: "New device registrations use a WebAuthn passkey for the Gorape RP, separate from the Keycloak credential. The private key stays with the OS/provider, which controls syncing. The local legacy passkey strategy preference does not change registration or server policy.",
  ),
  "MCODE-00457": AppMessage(
    ja: "Gorapeのcreation optionsから登録し、完全なWebAuthn credential responseを送信します。サーバーはRP ID、origin、challenge、credential public key、attestation statement、信頼チェーンを検証します。",
    en: "Registration uses Gorape creation options and submits the complete WebAuthn credential response. The server verifies the RP ID, origin, challenge, credential public key, attestation statement, and trust chain.",
  ),
  "MCODE-00458": AppMessage(
    ja: "既定では許可formatなし、none拒否、self-attestation拒否です。Application.Server.Attestation.WebAuthn.allowed_formats、allow_none、trust_anchorsを明示しない登録は拒否されます。",
    en: "By default, no attestation formats are allowed, none and self-attestation are rejected, and registration fails unless allowed_formats, allow_none, and trust_anchors are explicitly configured.",
  ),
  "MCODE-00459": AppMessage(
    ja: "Android Credential ManagerとApple AuthenticationServicesからWebAuthn応答を取得します。Androidはandroid-key等、Appleはappleまたはnone等になり得ます。attestation preferenceはbest-effortで、返されたfmtと証明書チェーンをGorape policyが判定します。",
    en: "WebAuthn responses come from Android Credential Manager or Apple AuthenticationServices. Android may return android-key and Apple may return apple or none. Attestation conveyance is best-effort; Gorape policy checks the returned format and certificate chain.",
  ),
  "MCODE-00460": AppMessage(
    ja: "WindowsはWindows WebAuthn API、WebはブラウザーのWebAuthnを使います。TPM attestationや直接attestationが返る保証はなく、policyが未対応形式を拒否します。Linuxは現在のFlutter passkeys pluginに実装がないためfail closedです。OIDC login supportとは別に管理します。",
    en: "Windows uses the Windows WebAuthn API and Web uses browser WebAuthn. TPM or direct attestation is not guaranteed, and policy rejects unsupported formats. Linux uses Chrome/Firefox through the gf-app browser ceremony because the Flutter passkeys plugin has no Linux implementation. This is separate from OIDC login support.",
  ),
  "MCODE-00461": AppMessage(
    ja: "RPとcredentialの境界",
    en: "RP and credential boundaries",
  ),
  "MCODE-00462": AppMessage(
    ja: "Keycloakでサインインし、Gorape RP用のパスキーを別途登録します。\nKeycloak用credentialはログイン用、Gorape用credentialはdevice proof用です。",
    en: "Sign in with Keycloak, then register a separate passkey for the Gorape RP.\nThe Keycloak credential is for sign-in; the Gorape credential is for device proof.",
  ),
  "MCODE-00463": AppMessage(
    ja: "管理者機能を使う場合は、管理者ロールを持つKeycloakアカウントでログインしてください。権限を切り替える場合は、ログアウトしてから再ログインしてください。",
    en: "To use administrator features, sign in with a Keycloak account that has the administrator role. Sign out and sign in again to switch accounts.",
  ),
  "MCODE-00464": AppMessage(
    ja: "パスキー秘密鍵はOS/browser credential providerが管理します。gf-appは秘密鍵を読み出さず、Gorapeは登録時にcredential公開鍵を保存します。",
    en: "The OS/browser credential provider manages passkey private keys. gf-app cannot read them; Gorape stores only the credential public key during registration.",
  ),
  "MCODE-00465": AppMessage(
    ja: "Gorapeが発行するchallengeをpasskey providerで署名し、RP ID・origin・credential・signatureをサーバーが検証します。",
    en: "The passkey provider signs a Gorape-issued challenge. The server verifies the RP ID, origin, credential, and signature.",
  ),
  "MCODE-00466": AppMessage(
    ja: "Gorape側でデバイスがrevokedになります。\nGorapeは以後このcredentialを受け付けません。provider内のcredentialは残る場合があり、同期設定によっては他端末にも影響するため、削除は必要な場合のみprovider側で行ってください。サーバー側の失効は元に戻せません。",
    en: "The device will be revoked in Gorape.\nGorape will no longer accept this credential. It may remain with the provider and, depending on sync settings, affect other devices. Remove it from the provider only if needed. Server-side revocation cannot be undone.",
  ),
  "MCODE-00467": AppMessage(
    ja: "Gorape RP専用のWebAuthn登録を実行し、credentialとattestationObject全体をGorapeへ送信します。",
    en: "Run WebAuthn registration for the Gorape RP and send Gorape the complete credential and attestationObject.",
  ),
  "MCODE-00468": AppMessage(
    ja: "attestationの有無・形式・信頼性はOS/providerが決定します。登録可否はGorapeの設定済みpolicyとverifierが判定します。",
    en: "The OS/provider determines whether attestation is returned and its format. Gorape's configured policy and verifier decide whether registration is accepted.",
  ),
  "MCODE-00469": AppMessage(
    ja: "作成challengeとattestation conveyance preferenceはGorapeが発行します。既定policyはattestationなし／未対応形式を拒否し、trust anchorや許可形式が未設定の場合も登録は失敗します。",
    en: "Gorape issues the creation challenge and attestation conveyance preference. By default, registrations without attestation or with unsupported formats are rejected; registration also fails when trust anchors or allowed formats are missing.",
  ),
  "MCODE-00470": AppMessage(
    ja: "このプラットフォームではpasskey登録pluginが未対応です。",
    en: "The passkey registration plugin is unavailable on this platform.",
  ),
  "MCODE-00471": AppMessage(
    ja: "GorapeがWebAuthn ceremonyとattestation policyを検証しました。続けてパスキーassertionによる所有証明を実行できます。",
    en: "Gorape verified the WebAuthn ceremony and attestation policy. You can now prove possession with a passkey assertion.",
  ),
  "MCODE-00472": AppMessage(
    ja: "ログインとデバイス所有証明",
    en: "Sign-in and device possession proof",
  ),
  "MCODE-00473": AppMessage(ja: "Passkey credential", en: "Passkey credential"),
  "MCODE-00474": AppMessage(
    ja: "Gorape RP用パスキーとattestation policy",
    en: "Gorape RP passkeys and attestation policy",
  ),
  "MCODE-00475": AppMessage(
    ja: "Gorape RP用パスキーceremony",
    en: "Gorape RP passkey ceremony",
  ),
  "MCODE-00476": AppMessage(ja: "パスキー鍵の保管", en: "Passkey key storage"),
  "MCODE-00477": AppMessage(
    ja: "WebAuthn登録ceremony",
    en: "WebAuthn registration ceremony",
  ),
  "MCODE-00478": AppMessage(
    ja: "attestationObject受け渡し",
    en: "Attestation response forwarding",
  ),
  "MCODE-00479": AppMessage(
    ja: "• 値はOSのセキュアストレージに保存されます。\n• Gorapeへは送信されません（ポリシーAPIがないため）。\n• サーバー側の強制が必要な場合は、GorapeにデバイスポリシーAPIを追加してから接続してください。",
    en: "• Values are stored in the OS secure storage.\n• They are not sent to Gorape because no policy API is available.\n• Add a device policy API to Gorape before connecting if server-side enforcement is required.",
  ),
  "MCODE-00480": AppMessage(
    ja: "Authorization Code + PKCE（S256）、scopes: openid profile、audience: gorape-api。Gorape APIにはAccess Tokenのみを使用し、ID Tokenは送信しません。Windows/Linuxはsystem browser loopback、Webは同一originのauth.html callbackを使います。",
    en: "Authorization Code + PKCE (S256), scopes: openid profile, audience: gorape-api. Only the access token is used with the Gorape API; the ID token is not sent. Windows/Linux use a system-browser loopback callback, while Web uses the same-origin auth.html callback.",
  ),
  "MCODE-00481": AppMessage(
    ja: "Keycloakの gorape-client に以下を登録してください。既存CLI用の http://127.0.0.1:8400/callback は変更・削除しません。Web app originはKeycloakのwebOriginsにも追加してください。",
    en: "Register these URIs on the Keycloak gorape-client. Keep the existing CLI callback http://127.0.0.1:8400/callback. Also add the Web app origin to Keycloak webOrigins.",
  ),
  "MCODE-00482": AppMessage(
    ja: "ローカルKeycloakの例: admin CLIで clients/gorape-client の redirectUris に追加します。詳細は README を参照してください。",
    en: "Local Keycloak example: add the URIs to clients/gorape-client redirectUris using the admin CLI. See the README for details.",
  ),
  "MCODE-00483": AppMessage(
    ja: "HTTP接続はローカル開発専用です。本番ではHTTPSと正規のRedirect URIを使用してください。",
    en: "HTTP is for local development only. Use HTTPS and a registered redirect URI in production.",
  ),
  "MCODE-00484": AppMessage(
    ja: "Android Emulatorでは OIDC 用に `adb reverse tcp:8080 tcp:8080` を実行してください。APIは既定で 10.0.2.2:8000 を利用します。",
    en: "For OIDC on an Android emulator, run `adb reverse tcp:8080 tcp:8080`. The API defaults to 10.0.2.2:8000.",
  ),
  "MCODE-00485": AppMessage(
    ja: "Gorape RPへパスキーを登録",
    en: "Register a passkey for the Gorape RP",
  ),
  "MCODE-00486": AppMessage(
    ja: "クラスタのロールはKeycloakのrealm/clientロールから判定しています。Gorapeの実認可はDBのproject/groupロール付与で行われます。",
    en: "Cluster roles are derived from Keycloak realm/client roles. Gorape authorization uses project/group role bindings in its database.",
  ),
  "MCODE-00487": AppMessage(
    ja: "プロジェクトがまだ作成されていません。\nGorapeリポジトリのgorape-adminでプロジェクトをbootstrapし、ユーザーにadmin/editor/viewerを付与してください。\n「管理」タブではKeycloakトークンのロールとグループを確認できます。",
    en: "No projects have been created yet.\nBootstrap a project with gorape-admin from the Gorape repository, then assign admin/editor/viewer roles to users.\nCheck Keycloak token roles and groups in the Management tab.",
  ),
  "MCODE-00488": AppMessage(
    ja: "Gorapeへ完全な応答を転送",
    en: "Forward the complete response to Gorape",
  ),
  "MCODE-00489": AppMessage(
    ja: "Gorape RP用creation optionsと単一使用challengeを取得",
    en: "Get Gorape RP creation options and a single-use challenge",
  ),
  "MCODE-00490": AppMessage(
    ja: "OS/browser passkey providerでWebAuthn登録",
    en: "Register with WebAuthn using the OS/browser passkey provider",
  ),
  "MCODE-00491": AppMessage(
    ja: "attestationObjectとclientDataJSONを含むcredential応答を送信",
    en: "Submit the credential response, including attestationObject and clientDataJSON",
  ),
  "MCODE-00492": AppMessage(
    ja: "Gorapeがchallenge、RP ID、origin、credential、attestationを検証",
    en: "Gorape verifies the challenge, RP ID, origin, credential, and attestation",
  ),
  "MCODE-00493": AppMessage(
    ja: "none／未対応形式／trust未設定はconfig policyで拒否",
    en: "The config policy rejects none, unsupported formats, and missing trust anchors",
  ),
  "MCODE-00494": AppMessage(
    ja: "Gorape RP用のパスキーをOS/browser credential providerに登録してください。\n登録後、WebAuthn assertionで所有証明を実行できます。",
    en: "Register a Gorape RP passkey with the OS/browser credential provider.\nAfter registration, prove possession with a WebAuthn assertion.",
  ),
  "MCODE-00495": AppMessage(
    ja: "この端末: {{name}}。パスキーはGorape RPへ個別登録します。Verifier statusは従来のAndroid Keystore鍵経路を示し、WebAuthn attestation policyとは別です。",
    en: "This device: {{name}}. Passkeys are registered separately for the Gorape RP. Verifier status describes the legacy Android Keystore key path and is separate from WebAuthn attestation policy.",
  ),
  "MCODE-00496": AppMessage(ja: "削除", en: "Delete"),
  "MCODE-00497": AppMessage(ja: "plugin未対応", en: "Plugin unavailable"),
  "MCODE-00498": AppMessage(
    ja: "このスコープではデバイスを登録できません。管理者または編集者のロールが必要です。",
    en: "You cannot register devices in this scope. An administrator or editor role is required.",
  ),
  "MCODE-00499": AppMessage(
    ja: "{{prefix}}: {{label}}",
    en: "{{prefix}}: {{label}}",
  ),
  "MCODE-00500": AppMessage(
    ja: "{{title}}: {{message}}",
    en: "{{title}}: {{message}}",
  ),
  "MCODE-00501": AppMessage(
    ja: "Android / iOS / macOS",
    en: "Android / iOS / macOS",
  ),
  "MCODE-00502": AppMessage(
    ja: "Windows / Web / Linux",
    en: "Windows / Web / Linux",
  ),
  "MCODE-00503": AppMessage(
    ja: "Gorapeのattestation policy",
    en: "Gorape attestation policy",
  ),
  "MCODE-00504": AppMessage(
    ja: "Keycloakパスキーを登録",
    en: "Register a Keycloak passkey",
  ),
  "MCODE-00505": AppMessage(ja: "パスキーでログイン", en: "Sign in with a passkey"),
  "MCODE-00506": AppMessage(
    ja: "Keycloakパスキーを登録しました。続けてパスキーでログインしてください。",
    en: "Keycloak passkey registered. Sign in with your passkey to enable device actions.",
  ),
  "MCODE-00507": AppMessage(
    ja: "パスキー登録をキャンセルしました。",
    en: "Passkey registration was cancelled.",
  ),
  "MCODE-00508": AppMessage(
    ja: "デバイス操作にはKeycloakパスキーでのログインが必要です。",
    en: "Sign in with your Keycloak passkey to use device actions.",
  ),
  "MCODE-00509": AppMessage(
    ja: "このログインではパスキーが使用されていません。デバイス操作にはパスキーでログインしてください。",
    en: "This session did not use a passkey. Sign in with a passkey to use device actions.",
  ),
  "MCODE-00510": AppMessage(
    ja: "Keycloakがこのログインをパスキー認証として確認できませんでした。パスキーを選択して再ログインしてください。",
    en: "Keycloak did not confirm passkey authentication. Select a passkey and sign in again.",
  ),
  "MCODE-00511": AppMessage(
    ja: "Keycloakパスキー登録の完了を確認できませんでした。",
    en: "Could not confirm that Keycloak passkey registration completed.",
  ),
  "MCODE-00512": AppMessage(
    ja: "KeycloakのWebauthn Register Passwordless required actionを確認してください。",
    en: "Check that the Webauthn Register Passwordless required action is enabled in Keycloak.",
  ),
  "MCODE-00513": AppMessage(
    ja: "Keycloakパスキー登録のOIDC応答を検証できませんでした。",
    en: "Could not validate the OIDC response for Keycloak passkey registration.",
  ),
  "MCODE-00514": AppMessage(
    ja: "Keycloakパスキー登録の応答を検証できませんでした。",
    en: "Could not validate the Keycloak passkey registration response.",
  ),
  "MCODE-00515": AppMessage(
    ja: "Keycloakパスキーの登録に失敗しました。",
    en: "Keycloak passkey registration failed.",
  ),
};

final Map<String, String> appMessageCodeByJapanese = <String, String>{
  for (final entry in appMessageCatalog.entries) entry.value.ja: entry.key,
};
