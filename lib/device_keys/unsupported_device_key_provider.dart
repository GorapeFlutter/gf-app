import 'dart:typed_data';

import 'device_key_provider.dart';

/// Explicitly unsupported provider.
///
/// Gorape currently reports Windows TPM and Apple attestation as unsupported.
/// The Flutter side models the interface but does not pretend the backend can
/// verify these platforms.
class UnsupportedDeviceKeyProvider implements DeviceKeyProvider {
  const UnsupportedDeviceKeyProvider({
    required this.platform,
    required this.reason,
  });

  @override
  final String platform;
  final String reason;

  @override
  Future<DeviceKeyAvailability> availability() async =>
      DeviceKeyAvailability.unsupported(reason);

  @override
  Future<GeneratedDeviceKey> generateKey({
    required String keyIdentifier,
    required Uint8List attestationChallenge,
  }) async {
    throw UnsupportedError(reason);
  }

  @override
  Future<String> sign({
    required String keyIdentifier,
    required Uint8List data,
  }) async {
    throw UnsupportedError(reason);
  }

  @override
  Future<bool> hasKey(String keyIdentifier) async => false;

  @override
  Future<void> deleteKey(String keyIdentifier) async {}
}
