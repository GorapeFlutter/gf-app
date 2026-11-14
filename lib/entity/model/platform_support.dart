/// Static, app-side support information.
///
/// Backend verifier support is fetched separately from
/// `GET /v1/projects/{projectId}/attestation/capabilities` and may be
/// "unconfigured" even on Android.
class PlatformSupport {
  /// GF-00304 — Initializes PlatformSupport.
  const PlatformSupport({
    required this.platform,
    required this.oidcLogin,
    required this.localKeyGeneration,
    required this.attestationFlow,
    required this.passkeyCeremony,
    required this.note,
  });

  final String platform;
  final bool oidcLogin;
  final bool localKeyGeneration;
  final bool attestationFlow;
  final bool passkeyCeremony;
  final String note;

  /// Keycloak and Gorape are separate WebAuthn relying parties.
  static const passkeyDelegationNote =
      'Keycloak用パスキーとは別にGorape RP用パスキーを登録します。'
      '秘密鍵はOS/browser credential providerに残り、gf-appやGorapeへ送信されません。';
}
