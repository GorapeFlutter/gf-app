import 'package:flutter/services.dart';

import '../../entity/model/credential_provider_status.dart';
import '../../entity/model/platform.dart';

/// Android integration for the system Credential Provider settings.
///
/// WebAuthn create/get ceremonies still run through [PasskeyRepository]; the
/// Android Credential Manager then dispatches requests to the native provider
/// service declared by gf-app.
abstract interface class CredentialProviderRepository {
  /// GF-01186 — Reads Android Credential Provider support and registration.
  Future<CredentialProviderStatus> status();

  /// GF-01187 — Opens the system credential-provider settings screen.
  Future<void> openSettings();
}

final class AndroidCredentialProviderRepository
    implements CredentialProviderRepository {
  /// GF-01188 — Initializes the Android Credential Provider repository.
  AndroidCredentialProviderRepository({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.gorapeflutter.gf_app/credential_provider';
  final MethodChannel _channel;

  /// GF-01189 — Reads native Android Credential Provider status.
  @override
  Future<CredentialProviderStatus> status() async {
    final result = await _channel.invokeMapMethod<Object?, Object?>('status');
    if (result == null) {
      throw const FormatException(
        'Android Credential Provider returned no status.',
      );
    }
    return CredentialProviderStatus.fromMap(result);
  }

  /// GF-01190 — Opens Android's Passwords and Passkeys settings.
  @override
  Future<void> openSettings() async {
    final opened = await _channel.invokeMethod<bool>('openSettings');
    if (opened != true) {
      throw UnsupportedError(
        'Android Credential Provider settings are unavailable on this device.',
      );
    }
  }
}

final class UnsupportedCredentialProviderRepository
    implements CredentialProviderRepository {
  /// GF-01191 — Initializes the unsupported-platform provider repository.
  const UnsupportedCredentialProviderRepository();

  /// GF-01192 — Reports Credential Provider as unavailable off Android.
  @override
  Future<CredentialProviderStatus> status() async =>
      const CredentialProviderStatus(
        apiLevel: 0,
        supported: false,
        serviceRegistered: false,
      );

  /// GF-01193 — Rejects opening Android settings on unsupported platforms.
  @override
  Future<void> openSettings() => Future<void>.error(
    UnsupportedError(
      'Credential Provider settings are only available on Android.',
    ),
  );
}

/// GF-01194 — Selects the platform's Credential Provider settings repository.
CredentialProviderRepository newCredentialProviderRepository(
  RuntimePlatform platform,
) => platform == RuntimePlatform.android
    ? AndroidCredentialProviderRepository()
    : const UnsupportedCredentialProviderRepository();
