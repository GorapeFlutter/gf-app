import 'package:flutter/services.dart';

import '../../entity/model/credential_provider_status.dart';
import '../../entity/model/platform.dart';

/// Android integration for the system Credential Provider settings.
///
/// WebAuthn create/get ceremonies still run through [PasskeyRepository]; the
/// Android Credential Manager then dispatches requests to the native provider
/// service declared by gf-app.
abstract interface class CredentialProviderRepository {
  Future<CredentialProviderStatus> status();

  Future<void> openSettings();
}

final class AndroidCredentialProviderRepository
    implements CredentialProviderRepository {
  AndroidCredentialProviderRepository({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.gorapeflutter.gf_app/credential_provider';
  final MethodChannel _channel;

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
  const UnsupportedCredentialProviderRepository();

  @override
  Future<CredentialProviderStatus> status() async =>
      const CredentialProviderStatus(
        apiLevel: 0,
        supported: false,
        serviceRegistered: false,
      );

  @override
  Future<void> openSettings() => Future<void>.error(
    UnsupportedError(
      'Credential Provider settings are only available on Android.',
    ),
  );
}

CredentialProviderRepository newCredentialProviderRepository(
  RuntimePlatform platform,
) => platform == RuntimePlatform.android
    ? AndroidCredentialProviderRepository()
    : const UnsupportedCredentialProviderRepository();
