import '../core/config/runtime_platform.dart';
import 'android_device_key_provider.dart';
import 'device_key_provider.dart';
import 'unsupported_device_key_provider.dart';

/// Selects the OS key provider.
///
/// Android is the only platform with a working hardware-backed registration
/// path at the moment. The remaining platforms intentionally report
/// unsupported instead of generating keys that Gorape cannot verify.
DeviceKeyProvider createDeviceKeyProvider(RuntimePlatform platform) {
  return switch (platform) {
    RuntimePlatform.android => AndroidDeviceKeyProvider(),
    RuntimePlatform.windows => const UnsupportedDeviceKeyProvider(
      platform: 'windows',
      reason:
          'Windows TPM attestation is reported as unsupported by the current Gorape backend.',
    ),
    RuntimePlatform.ios => const UnsupportedDeviceKeyProvider(
      platform: 'ios',
      reason:
          'iOS attestation is reported as unsupported by the current Gorape backend.',
    ),
    RuntimePlatform.macos => const UnsupportedDeviceKeyProvider(
      platform: 'macos',
      reason:
          'macOS attestation is reported as unsupported by the current Gorape backend.',
    ),
    RuntimePlatform.linux => const UnsupportedDeviceKeyProvider(
      platform: 'linux',
      reason: 'Gorape does not define a Linux attestation platform.',
    ),
    RuntimePlatform.web => const UnsupportedDeviceKeyProvider(
      platform: 'web',
      reason: 'Browsers do not expose the OS attestation key store used here.',
    ),
    RuntimePlatform.unknown => const UnsupportedDeviceKeyProvider(
      platform: 'unknown',
      reason: 'Unknown platform.',
    ),
  };
}
