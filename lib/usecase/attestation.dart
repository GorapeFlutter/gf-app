import '../repository/attestation.dart';
import '../entity/model/attestation.dart';
import '../entity/response/attestation.dart';

abstract interface class AttestationUsecase {
  Future<AttestationCapabilities> capabilities(String projectId);
  Future<List<AttestationRecord>> list(String projectId, String deviceId);
}

final class AttestationUsecaseImpl implements AttestationUsecase {
  const AttestationUsecaseImpl(this._repository);
  final AttestationRepository _repository;

  @override
  Future<AttestationCapabilities> capabilities(String projectId) =>
      _repository.capabilities(projectId);
  @override
  Future<List<AttestationRecord>> list(String projectId, String deviceId) =>
      _repository.list(projectId, deviceId);
}

AttestationUsecase newAttestationUsecase(AttestationRepository repository) =>
    AttestationUsecaseImpl(repository);
