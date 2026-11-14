/// WebAuthn credential response submitted to Gorape after registration.
class PasskeyRegistrationVerifyRequest {
  const PasskeyRegistrationVerifyRequest({
    required this.challengeId,
    required this.platform,
    required this.displayName,
    required this.credential,
  });

  final String challengeId;
  final String platform;
  final String displayName;

  /// Complete WebAuthn PublicKeyCredential JSON, including
  /// `response.attestationObject` and `response.clientDataJSON`.
  final Map<String, dynamic> credential;

  Map<String, dynamic> toJson() => {
    'challenge_id': challengeId,
    'platform': platform,
    'display_name': displayName,
    'credential': credential,
  };
}

/// WebAuthn assertion submitted to Gorape to prove possession of a device
/// passkey.
class PasskeyAuthenticationVerifyRequest {
  const PasskeyAuthenticationVerifyRequest({
    required this.challengeId,
    required this.credential,
  });

  final String challengeId;

  /// Complete WebAuthn PublicKeyCredential JSON, including authenticator data,
  /// client data, and signature.
  final Map<String, dynamic> credential;

  Map<String, dynamic> toJson() => {
    'challenge_id': challengeId,
    'credential': credential,
  };
}
