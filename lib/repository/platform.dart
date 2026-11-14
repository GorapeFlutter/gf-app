import 'package:flutter/foundation.dart';

import '../entity/model/platform.dart';
import '../entity/model/platform_support.dart';

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

/// GF-00582 — Creates an instance for new platform repository.
PlatformRepository newPlatformRepository() => const PlatformRepositoryImpl();
