/// Platforms the client knows how to describe.
///
/// Runtime detection itself belongs to `repository/platform.dart`.
enum RuntimePlatform {
  android,
  ios,
  macos,
  windows,
  linux,
  web,
  unknown;

  /// GF-00301 — Computes RuntimePlatform.wireName.
  String get wireName => switch (this) {
    RuntimePlatform.android => 'android',
    RuntimePlatform.ios => 'ios',
    RuntimePlatform.macos => 'macos',
    RuntimePlatform.windows => 'windows',
    RuntimePlatform.linux => 'linux',
    RuntimePlatform.web => 'web',
    RuntimePlatform.unknown => 'unknown',
  };

  /// GF-00302 — Computes RuntimePlatform.displayName.
  String get displayName => switch (this) {
    RuntimePlatform.android => 'Android',
    RuntimePlatform.ios => 'iOS',
    RuntimePlatform.macos => 'macOS',
    RuntimePlatform.windows => 'Windows',
    RuntimePlatform.linux => 'Linux',
    RuntimePlatform.web => 'Web',
    RuntimePlatform.unknown => 'Unknown',
  };

  /// GF-00303 — Computes RuntimePlatform.isApple.
  bool get isApple =>
      this == RuntimePlatform.ios || this == RuntimePlatform.macos;
}
