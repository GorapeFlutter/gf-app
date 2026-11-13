import '../model/device.dart';
import '../model/registered_device_key.dart';

class RegistrationResult {
  const RegistrationResult({
    required this.device,
    required this.key,
    required this.securityLevel,
  });

  final Device device;
  final RegisteredDeviceKey key;
  final String? securityLevel;
}
