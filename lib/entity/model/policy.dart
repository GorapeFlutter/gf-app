import 'dart:convert';

/// How a login credential is associated with a device.
///
/// Both modes are requirements of the Flutter client. Keycloak owns passkeys
/// and MFA; Gorape owns device keys. This abstraction does not invent a
/// backend policy API.
enum PasskeyStrategy {
  /// A passkey may be shared with the user's Keycloak account across devices.
  sharedPasskey,

  /// A dedicated device key is registered with Gorape and used for proof.
  dedicatedDeviceKey,
}

class LocalDevicePolicy {
  const LocalDevicePolicy({
    this.allowDevicesWithoutAttestation = false,
    this.requireProofAfterLogin = true,
    this.passkeyStrategy = PasskeyStrategy.dedicatedDeviceKey,
  });

  final bool allowDevicesWithoutAttestation;
  final bool requireProofAfterLogin;
  final PasskeyStrategy passkeyStrategy;

  LocalDevicePolicy copyWith({
    bool? allowDevicesWithoutAttestation,
    bool? requireProofAfterLogin,
    PasskeyStrategy? passkeyStrategy,
  }) {
    return LocalDevicePolicy(
      allowDevicesWithoutAttestation:
          allowDevicesWithoutAttestation ?? this.allowDevicesWithoutAttestation,
      requireProofAfterLogin:
          requireProofAfterLogin ?? this.requireProofAfterLogin,
      passkeyStrategy: passkeyStrategy ?? this.passkeyStrategy,
    );
  }

  Map<String, dynamic> toJson() => {
    'allow_devices_without_attestation': allowDevicesWithoutAttestation,
    'require_proof_after_login': requireProofAfterLogin,
    'passkey_strategy': passkeyStrategy.name,
  };

  factory LocalDevicePolicy.fromJson(Map<String, dynamic> json) {
    final raw = json['passkey_strategy'];
    return LocalDevicePolicy(
      allowDevicesWithoutAttestation:
          json['allow_devices_without_attestation'] == true,
      requireProofAfterLogin: json['require_proof_after_login'] != false,
      passkeyStrategy: PasskeyStrategy.values.firstWhere(
        (value) => value.name == raw,
        orElse: () => PasskeyStrategy.dedicatedDeviceKey,
      ),
    );
  }

  static LocalDevicePolicy decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid policy');
    }
    return LocalDevicePolicy.fromJson(decoded);
  }

  String encode() => jsonEncode(toJson());
}

/// Backend policy support is explicitly absent from the current OpenAPI spec.
class PolicyCapabilities {
  const PolicyCapabilities({
    required this.backendSupported,
    required this.reason,
  });

  static const none = PolicyCapabilities(
    backendSupported: false,
    reason:
        '現行のGorape OpenAPI 3.1にはデバイスポリシー設定APIがありません。'
        'この画面の設定は端末内の希望値であり、バックエンドで強制されません。',
  );

  final bool backendSupported;
  final String reason;
}
