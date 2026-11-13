/// Local capabilities of an OS key provider.
class DeviceKeyAvailability {
  const DeviceKeyAvailability({
    required this.supported,
    required this.hardwareBacked,
    required this.attestationSupported,
    this.securityLevel,
    this.reason,
  });

  const DeviceKeyAvailability.unsupported(this.reason)
    : supported = false,
      hardwareBacked = false,
      attestationSupported = false,
      securityLevel = null;

  final bool supported;
  final bool hardwareBacked;
  final bool attestationSupported;
  final String? securityLevel;
  final String? reason;
}

/// Public material produced by an OS key store. Private key bytes never leave it.
class GeneratedDeviceKey {
  const GeneratedDeviceKey({
    required this.keyIdentifier,
    required this.publicKeyPem,
    required this.algorithm,
    required this.evidence,
    this.securityLevel,
  });

  final String keyIdentifier;
  final String publicKeyPem;
  final String algorithm;
  final Map<String, dynamic> evidence;
  final String? securityLevel;
}
