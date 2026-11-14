import '../entity/model/attestation.dart';
import '../entity/response/attestation.dart';
import 'gorape.dart';

abstract interface class AttestationRepository {
  /// GF-00405 — Handles capabilities in AttestationRepository.
  Future<AttestationCapabilities> capabilities(String projectId);

  /// GF-00406 — Handles list in AttestationRepository.
  Future<List<AttestationRecord>> list(String projectId, String deviceId);
}

final class AttestationRepositoryImpl implements AttestationRepository {
  /// GF-00407 — Initializes AttestationRepositoryImpl.
  const AttestationRepositoryImpl(this._api);

  final GorapeApi _api;

  /// GF-00408 — Handles capabilities in AttestationRepositoryImpl.
  @override
  Future<AttestationCapabilities> capabilities(String projectId) =>
      _api.attestationCapabilities(projectId);

  /// GF-00409 — Handles list in AttestationRepositoryImpl.
  @override
  Future<List<AttestationRecord>> list(String projectId, String deviceId) =>
      _api.attestations(projectId, deviceId);
}

/// GF-00410 — Creates an instance for new attestation repository.
AttestationRepository newAttestationRepository(GorapeApi api) =>
    AttestationRepositoryImpl(api);
