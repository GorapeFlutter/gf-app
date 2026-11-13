/// Registration and proof challenge returned by Gorape.
class Challenge {
  const Challenge({
    required this.challengeId,
    required this.challenge,
    required this.expiresAt,
  });

  final String challengeId;

  /// Unpadded Base64url random bytes.
  final String challenge;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory Challenge.fromJson(Map<String, dynamic> json) {
    final expiresAt = json['expires_at'];
    return Challenge(
      challengeId: json['challenge_id'] as String? ?? '',
      challenge: json['challenge'] as String? ?? '',
      expiresAt: expiresAt is String
          ? DateTime.tryParse(expiresAt) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
