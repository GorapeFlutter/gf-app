import '../model/device.dart';
import '../model/registered_device_key.dart';

class RegistrationResult {
  /// GF-00396 — Initializes RegistrationResult.
  const RegistrationResult({
    required this.device,
    required this.key,
    required this.securityLevel,
  });

  final Device device;
  final RegisteredDeviceKey key;
  final String? securityLevel;
}
