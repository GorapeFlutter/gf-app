/// Payload for `POST /v1/projects/{projectId}/devices/registration/verify`.
///
/// Field names match `components.schemas.RegistrationVerify` in the Gorape
/// OpenAPI 3.1 contract.
class RegistrationVerifyRequest {
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
  const ProofVerifyRequest({
    required this.challengeId,
    required this.signature,
  });

  final String challengeId;

  /// Base64url encoded signature.
  final String signature;

  Map<String, dynamic> toJson() => {
    'challenge_id': challengeId,
    'signature': signature,
  };
}

class ApiErrorBody {
  const ApiErrorBody({required this.code, required this.message});

  final String code;
  final String message;

  factory ApiErrorBody.fromJson(Map<String, dynamic> json) {
    return ApiErrorBody(
      code: json['code'] as String? ?? 'request_failed',
      message: json['message'] as String? ?? 'Request failed.',
    );
  }
}
