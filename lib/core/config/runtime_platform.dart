import 'package:flutter/foundation.dart';

/// Platforms the client knows how to describe.
///
/// The enum is deliberately independent from [TargetPlatform] so tests can
/// exercise platform-specific behaviour without changing the host platform.
enum RuntimePlatform {
  android,
  ios,
  macos,
  windows,
  linux,
  web,
  unknown;

  static RuntimePlatform current() {
    if (kIsWeb) return RuntimePlatform.web;
    return fromTargetPlatform(defaultTargetPlatform);
  }

  static RuntimePlatform fromTargetPlatform(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android => RuntimePlatform.android,
      TargetPlatform.iOS => RuntimePlatform.ios,
      TargetPlatform.macOS => RuntimePlatform.macos,
      TargetPlatform.windows => RuntimePlatform.windows,
      TargetPlatform.linux => RuntimePlatform.linux,
      TargetPlatform.fuchsia => RuntimePlatform.unknown,
    };
  }

  String get wireName => switch (this) {
    RuntimePlatform.android => 'android',
    RuntimePlatform.ios => 'ios',
    RuntimePlatform.macos => 'macos',
    RuntimePlatform.windows => 'windows',
    RuntimePlatform.linux => 'linux',
    RuntimePlatform.web => 'web',
    RuntimePlatform.unknown => 'unknown',
  };

  String get displayName => switch (this) {
    RuntimePlatform.android => 'Android',
    RuntimePlatform.ios => 'iOS',
    RuntimePlatform.macos => 'macOS',
    RuntimePlatform.windows => 'Windows',
    RuntimePlatform.linux => 'Linux',
    RuntimePlatform.web => 'Web',
    RuntimePlatform.unknown => 'Unknown',
  };

  bool get isApple =>
      this == RuntimePlatform.ios || this == RuntimePlatform.macos;
}
