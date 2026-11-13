import '../entity/model/attestation.dart';
import '../entity/response/attestation.dart';
import 'gorape.dart';

abstract interface class AttestationRepository {
  Future<AttestationCapabilities> capabilities(String projectId);

  Future<List<AttestationRecord>> list(String projectId, String deviceId);
}

final class AttestationRepositoryImpl implements AttestationRepository {
  const AttestationRepositoryImpl(this._api);

  final GorapeApi _api;

  @override
  Future<AttestationCapabilities> capabilities(String projectId) =>
      _api.attestationCapabilities(projectId);

  @override
  Future<List<AttestationRecord>> list(String projectId, String deviceId) =>
      _api.attestations(projectId, deviceId);
}

AttestationRepository newAttestationRepository(GorapeApi api) =>
    AttestationRepositoryImpl(api);
