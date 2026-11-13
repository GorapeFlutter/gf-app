/// Static, app-side support information.
///
/// Backend verifier support is fetched separately from
/// `GET /v1/projects/{projectId}/attestation/capabilities` and may be
/// "unconfigured" even on Android.
class PlatformSupport {
  const PlatformSupport({
    required this.platform,
    required this.oidcLogin,
    required this.localKeyGeneration,
    required this.attestationFlow,
    required this.note,
  });

  final String platform;
  final bool oidcLogin;
  final bool localKeyGeneration;
  final bool attestationFlow;
  final String note;

  /// Keycloak owns passkeys/MFA. The app only orchestrates the browser flow.
  static const passkeyDelegationNote =
      'パスキーとMFAはKeycloakが担当します。Gorapeはデバイス公開鍵と'
      '所有証明のみを扱い、パスワードやパスキー秘密情報を保存しません。';
}
