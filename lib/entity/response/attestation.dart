/// Attestation verifier support reported by the backend.
class AttestationCapabilities {
  /// GF-00387 — Initializes AttestationCapabilities.
  const AttestationCapabilities(this.verifiers);

  final Map<String, String> verifiers;

  /// GF-00388 — Initializes AttestationCapabilities.fromJson.
  factory AttestationCapabilities.fromJson(Map<String, dynamic> json) {
    final raw = json['verifiers'];
    if (raw is! Map) return const AttestationCapabilities({});
    return AttestationCapabilities({
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    });
  }

  /// GF-00389 — Handles status for in AttestationCapabilities.
  String statusFor(String platform) => verifiers[platform] ?? 'unknown';

  /// GF-00390 — Checks whether is implemented.
  bool isImplemented(String platform) => statusFor(platform) == 'implemented';
}
