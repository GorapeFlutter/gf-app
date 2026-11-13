/// Attestation verifier support reported by the backend.
class AttestationCapabilities {
  const AttestationCapabilities(this.verifiers);

  final Map<String, String> verifiers;

  factory AttestationCapabilities.fromJson(Map<String, dynamic> json) {
    final raw = json['verifiers'];
    if (raw is! Map) return const AttestationCapabilities({});
    return AttestationCapabilities({
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    });
  }

  String statusFor(String platform) => verifiers[platform] ?? 'unknown';

  bool isImplemented(String platform) => statusFor(platform) == 'implemented';
}
