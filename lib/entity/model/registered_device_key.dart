import 'dart:convert';

/// Locally persisted metadata for a registered device key.
///
/// Only the Keystore alias is stored. Private key bytes never leave Android
/// Keystore / Secure Enclave.
class RegisteredDeviceKey {
  const RegisteredDeviceKey({
    required this.projectId,
    required this.deviceId,
    required this.keyIdentifier,
    required this.algorithm,
    required this.platform,
    required this.displayName,
    required this.createdAt,
    this.securityLevel,
  });

  final String projectId;
  final String deviceId;
  final String keyIdentifier;
  final String algorithm;
  final String platform;
  final String displayName;
  final DateTime createdAt;
  final String? securityLevel;

  Map<String, dynamic> toJson() => {
    'project_id': projectId,
    'device_id': deviceId,
    'key_identifier': keyIdentifier,
    'algorithm': algorithm,
    'platform': platform,
    'display_name': displayName,
    'created_at': createdAt.toUtc().toIso8601String(),
    'security_level': securityLevel,
  };

  factory RegisteredDeviceKey.fromJson(Map<String, dynamic> json) {
    return RegisteredDeviceKey(
      projectId: json['project_id'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      keyIdentifier: json['key_identifier'] as String? ?? '',
      algorithm: json['algorithm'] as String? ?? 'ES256',
      platform: json['platform'] as String? ?? 'android',
      displayName: json['display_name'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      securityLevel: json['security_level'] as String?,
    );
  }

  static RegisteredDeviceKey decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid device key record');
    }
    return RegisteredDeviceKey.fromJson(decoded);
  }

  String encode() => jsonEncode(toJson());
}
