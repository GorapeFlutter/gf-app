/// Payload for `POST /v1/projects/{projectId}/devices/registration/verify`.
///
/// Field names match `components.schemas.RegistrationVerify` in the Gorape
/// OpenAPI 3.1 contract.
class RegistrationVerifyRequest {
  /// GF-00375 — Initializes RegistrationVerifyRequest.
  const RegistrationVerifyRequest({
    required this.challengeId,
    required this.platform,
    required this.displayName,
    required this.publicKeyPem,
    required this.keyIdentifier,
    required this.algorithm,
    required this.evidence,
  });

  final String challengeId;
  final String platform;
  final String displayName;
  final String publicKeyPem;
  final String keyIdentifier;
  final String algorithm;
  final Map<String, dynamic> evidence;

  /// GF-00376 — Serializes data in RegistrationVerifyRequest.
  Map<String, dynamic> toJson() => {
    'challenge_id': challengeId,
    'platform': platform,
    'display_name': displayName,
    'public_key_pem': publicKeyPem,
    'key_identifier': keyIdentifier,
    'algorithm': algorithm,
    'evidence': evidence,
  };
}

/// Payload for `POST /v1/projects/{projectId}/devices/{deviceId}/verify`.
class ProofVerifyRequest {
  /// GF-00377 — Initializes ProofVerifyRequest.
  const ProofVerifyRequest({
    required this.challengeId,
    required this.signature,
  });

  final String challengeId;

  /// Base64url encoded signature.
  final String signature;

  /// GF-00378 — Serializes data in ProofVerifyRequest.
  Map<String, dynamic> toJson() => {
    'challenge_id': challengeId,
    'signature': signature,
  };
}
