import '../core/config/runtime_platform.dart';

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

  static PlatformSupport forRuntime(RuntimePlatform platform) {
    return switch (platform) {
      RuntimePlatform.android => const PlatformSupport(
        platform: 'android',
        oidcLogin: true,
        localKeyGeneration: true,
        attestationFlow: true,
        note: 'Android Keystore + Key Attestation。バックエンドの信頼アンカー設定が必要です。',
      ),
      RuntimePlatform.ios => const PlatformSupport(
        platform: 'ios',
        oidcLogin: true,
        localKeyGeneration: false,
        attestationFlow: false,
        note: 'Keycloakログインのみ対応。AttestationはGorapeバックエンドがunsupportedを返します。',
      ),
      RuntimePlatform.macos => const PlatformSupport(
        platform: 'macos',
        oidcLogin: true,
        localKeyGeneration: false,
        attestationFlow: false,
        note: 'Keycloakログインのみ対応。AttestationはGorapeバックエンドがunsupportedを返します。',
      ),
      RuntimePlatform.windows => const PlatformSupport(
        platform: 'windows',
        oidcLogin: false,
        localKeyGeneration: false,
        attestationFlow: false,
        note: 'AppAuthのWindows実装はありません。TPM検証もバックエンド未対応です。',
      ),
      RuntimePlatform.linux => const PlatformSupport(
        platform: 'linux',
        oidcLogin: false,
        localKeyGeneration: false,
        attestationFlow: false,
        note: 'GorapeはLinuxをAttestation対象プラットフォームとして定義していません。',
      ),
      RuntimePlatform.web => const PlatformSupport(
        platform: 'web',
        oidcLogin: false,
        localKeyGeneration: false,
        attestationFlow: false,
        note: 'OS保護鍵を利用できないため対象外です。',
      ),
      RuntimePlatform.unknown => const PlatformSupport(
        platform: 'unknown',
        oidcLogin: false,
        localKeyGeneration: false,
        attestationFlow: false,
        note: 'プラットフォームを判定できません。',
      ),
    };
  }

  /// Keycloak owns passkeys/MFA. The app only orchestrates the browser flow.
  static const passkeyDelegationNote =
      'パスキーとMFAはKeycloakが担当します。Gorapeはデバイス公開鍵と'
      '所有証明のみを扱い、パスワードやパスキー秘密情報を保存しません。';
}
