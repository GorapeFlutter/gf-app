import 'package:flutter/foundation.dart';

import '../../entity/model/platform.dart';
import '../../entity/model/platform_support.dart';

abstract interface class PlatformRepository {
  /// GF-00577 — Handles current in PlatformRepository.
  RuntimePlatform current();

  /// GF-00578 — Handles support for in PlatformRepository.
  PlatformSupport supportFor(RuntimePlatform platform);
}

final class PlatformRepositoryImpl implements PlatformRepository {
  /// GF-00579 — Initializes PlatformRepositoryImpl.
  const PlatformRepositoryImpl();

  /// GF-00580 — Handles current in PlatformRepositoryImpl.
  @override
  RuntimePlatform current() {
    if (kIsWeb) return RuntimePlatform.web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => RuntimePlatform.android,
      TargetPlatform.iOS => RuntimePlatform.ios,
      TargetPlatform.macOS => RuntimePlatform.macos,
      TargetPlatform.windows => RuntimePlatform.windows,
      TargetPlatform.linux => RuntimePlatform.linux,
      TargetPlatform.fuchsia => RuntimePlatform.unknown,
    };
  }

  /// GF-00581 — Handles support for in PlatformRepositoryImpl.
  @override
  PlatformSupport supportFor(RuntimePlatform platform) => switch (platform) {
    RuntimePlatform.android => const PlatformSupport(
      platform: 'android',
      oidcLogin: true,
      localKeyGeneration: true,
      attestationFlow: true,
      passkeyCeremony: true,
      note:
          'Android passkey/WebAuthn登録に対応します。返されるattestation形式はcredential providerに依存します。',
    ),
    RuntimePlatform.ios => const PlatformSupport(
      platform: 'ios',
      oidcLogin: true,
      localKeyGeneration: false,
      attestationFlow: false,
      passkeyCeremony: true,
      note: 'Apple platform passkeyに対応します。OSが返すattestation形式・識別可能性は制御できません。',
    ),
    RuntimePlatform.macos => const PlatformSupport(
      platform: 'macos',
      oidcLogin: true,
      localKeyGeneration: false,
      attestationFlow: false,
      passkeyCeremony: true,
      note: 'Apple platform passkeyに対応します。OSが返すattestation形式・識別可能性は制御できません。',
    ),
    RuntimePlatform.windows => const PlatformSupport(
      platform: 'windows',
      oidcLogin: true,
      localKeyGeneration: true,
      attestationFlow: false,
      passkeyCeremony: true,
      note:
          'System browser + PKCE OIDC、Windows WebAuthn、CNG/TPMのnon-exportable Device鍵に対応します。'
          'パスキーの保証レベルはOSが返すTPM/attestation statementをGorapeが検証して決定します。',
    ),
    RuntimePlatform.linux => const PlatformSupport(
      platform: 'linux',
      oidcLogin: true,
      localKeyGeneration: false,
      attestationFlow: false,
      passkeyCeremony: true,
      note:
          'System browser + PKCE OIDCとGorape RP browser ceremonyに対応します。credential providerが返すattestationのみ検証します。',
    ),
    RuntimePlatform.web => const PlatformSupport(
      platform: 'web',
      oidcLogin: true,
      localKeyGeneration: false,
      attestationFlow: false,
      passkeyCeremony: true,
      note:
          'Browser redirect + PKCE OIDCとWebAuthnに対応します。attestationがnone/匿名化される場合はbackend policyで拒否されます。',
    ),
    RuntimePlatform.unknown => const PlatformSupport(
      platform: 'unknown',
      oidcLogin: false,
      localKeyGeneration: false,
      attestationFlow: false,
      passkeyCeremony: false,
      note: 'プラットフォームを判定できません。',
    ),
  };
}

/// GF-00582 — Creates an instance for new platform repository.
PlatformRepository newPlatformRepository() => const PlatformRepositoryImpl();
