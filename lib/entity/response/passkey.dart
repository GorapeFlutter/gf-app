import '../model/device.dart';

/// WebAuthn creation options produced by Gorape for its RP ID.
///
/// The server owns the RP ID, challenge, user handle, and attestation
/// conveyance preference. The client must pass [publicKey] to the platform
/// authenticator unchanged.
class PasskeyRegistrationOptions {
  const PasskeyRegistrationOptions({
    required this.challengeId,
    required this.publicKey,
    required this.expiresAt,
    this.browserUrl,
    this.browserApiOrigin,
  });

  final String challengeId;
  final Map<String, dynamic> publicKey;
  final DateTime expiresAt;
  final String? browserUrl;
  final String? browserApiOrigin;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory PasskeyRegistrationOptions.fromJson(Map<String, dynamic> json) {
    final publicKey = json['public_key'];
    if (publicKey is! Map) {
      throw const FormatException('Missing WebAuthn public_key options.');
    }
    final expiresAt = json['expires_at'];
    return PasskeyRegistrationOptions(
      challengeId: json['challenge_id'] as String? ?? '',
      publicKey: Map<String, dynamic>.from(publicKey),
      expiresAt: expiresAt is String
          ? DateTime.tryParse(expiresAt) ?? DateTime.now()
          : DateTime.now(),
      browserUrl: json['browser_url'] as String?,
      browserApiOrigin: json['browser_api_origin'] as String?,
    );
  }
}

/// WebAuthn request options produced by Gorape for a device assertion.
class PasskeyAuthenticationOptions {
  const PasskeyAuthenticationOptions({
    required this.challengeId,
    required this.publicKey,
    required this.expiresAt,
    this.browserUrl,
    this.browserApiOrigin,
  });

  final String challengeId;
  final Map<String, dynamic> publicKey;
  final DateTime expiresAt;
  final String? browserUrl;
  final String? browserApiOrigin;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory PasskeyAuthenticationOptions.fromJson(Map<String, dynamic> json) {
    final publicKey = json['public_key'];
    if (publicKey is! Map) {
      throw const FormatException('Missing WebAuthn public_key options.');
    }
    final expiresAt = json['expires_at'];
    return PasskeyAuthenticationOptions(
      challengeId: json['challenge_id'] as String? ?? '',
      publicKey: Map<String, dynamic>.from(publicKey),
      expiresAt: expiresAt is String
          ? DateTime.tryParse(expiresAt) ?? DateTime.now()
          : DateTime.now(),
      browserUrl: json['browser_url'] as String?,
      browserApiOrigin: json['browser_api_origin'] as String?,
    );
  }
}

/// Result returned after Gorape verifies both the WebAuthn ceremony and
/// platform attestation.
class PasskeyRegistrationResult {
  const PasskeyRegistrationResult({
    required this.device,
    required this.attestationType,
    required this.securityLevel,
    required this.verifierVersion,
  });

  final Device device;
  final String attestationType;
  final String securityLevel;
  final String verifierVersion;

  factory PasskeyRegistrationResult.fromJson(Map<String, dynamic> json) {
    final device = json['device'];
    final attestation = json['attestation'];
    if (device is! Map || attestation is! Map) {
      throw const FormatException(
        'Expected verified device and attestation in response.',
      );
    }
    return PasskeyRegistrationResult(
      device: Device.fromJson(Map<String, dynamic>.from(device)),
      attestationType: attestation['attestation_type'] as String? ?? '',
      securityLevel: attestation['security_level'] as String? ?? '',
      verifierVersion: attestation['verifier_version'] as String? ?? '',
    );
  }
}
