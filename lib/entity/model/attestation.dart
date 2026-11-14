/// One attestation verification record.
class AttestationRecord {
  /// GF-00250 — Initializes AttestationRecord.
  const AttestationRecord({
    required this.id,
    required this.projectId,
    required this.deviceKeyId,
    required this.attestationType,
    required this.securityLevel,
    required this.verificationStatus,
    required this.verifierVersion,
    required this.verifiedAt,
    this.evidenceReference,
  });

  final String id;
  final String projectId;
  final String deviceKeyId;
  final String attestationType;
  final String securityLevel;
  final String verificationStatus;
  final String verifierVersion;
  final DateTime verifiedAt;
  final String? evidenceReference;

  /// GF-00251 — Initializes AttestationRecord.fromJson.
  factory AttestationRecord.fromJson(Map<String, dynamic> json) {
    return AttestationRecord(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      deviceKeyId:
          json['key_id'] as String? ?? json['device_key_id'] as String? ?? '',
      attestationType: json['attestation_type'] as String? ?? '',
      securityLevel: json['security_level'] as String? ?? '',
      verificationStatus: json['verification_status'] as String? ?? '',
      verifierVersion: json['verifier_version'] as String? ?? '',
      verifiedAt:
          DateTime.tryParse(json['verified_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      evidenceReference: json['evidence_reference'] as String?,
    );
  }
}
