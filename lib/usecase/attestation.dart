import '../repository/attestation.dart';
import '../entity/model/attestation.dart';
import '../entity/response/attestation.dart';

abstract interface class AttestationUsecase {
  /// GF-01039 — Handles capabilities in AttestationUsecase.
  Future<AttestationCapabilities> capabilities(String projectId);

  /// GF-01040 — Handles list in AttestationUsecase.
  Future<List<AttestationRecord>> list(String projectId, String deviceId);
}

final class AttestationUsecaseImpl implements AttestationUsecase {
  /// GF-01041 — Initializes AttestationUsecaseImpl.
  const AttestationUsecaseImpl(this._repository);
  final AttestationRepository _repository;

  /// GF-01042 — Handles capabilities in AttestationUsecaseImpl.
  @override
  Future<AttestationCapabilities> capabilities(String projectId) =>
      _repository.capabilities(projectId);

  /// GF-01043 — Handles list in AttestationUsecaseImpl.
  @override
  Future<List<AttestationRecord>> list(String projectId, String deviceId) =>
      _repository.list(projectId, deviceId);
}

/// GF-01044 — Creates an instance for new attestation usecase.
AttestationUsecase newAttestationUsecase(AttestationRepository repository) =>
    AttestationUsecaseImpl(repository);
