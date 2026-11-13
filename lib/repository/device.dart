import '../entity/model/device.dart';
import '../entity/request/device.dart';
import '../entity/response/challenge.dart';
import 'gorape.dart';

abstract interface class DeviceRepository {
  Future<List<Device>> list(String projectId);

  Future<Device> get(String projectId, String deviceId);

  Future<void> revoke(String projectId, String deviceId);

  Future<Challenge> createRegistrationChallenge(
    String projectId, {
    required String platform,
  });

  Future<Device> verifyRegistration(
    String projectId,
    RegistrationVerifyRequest request,
  );

  Future<Challenge> createProofChallenge(String projectId, String deviceId);

  Future<void> verifyProof(
    String projectId,
    String deviceId,
    ProofVerifyRequest request,
  );
}

final class DeviceRepositoryImpl implements DeviceRepository {
  const DeviceRepositoryImpl(this._api);

  final GorapeApi _api;

  @override
  Future<List<Device>> list(String projectId) => _api.listDevices(projectId);

  @override
  Future<Device> get(String projectId, String deviceId) =>
      _api.getDevice(projectId, deviceId);

  @override
  Future<void> revoke(String projectId, String deviceId) =>
      _api.revokeDevice(projectId, deviceId);

  @override
  Future<Challenge> createRegistrationChallenge(
    String projectId, {
    required String platform,
  }) => _api.createRegistrationChallenge(projectId, platform: platform);

  @override
  Future<Device> verifyRegistration(
    String projectId,
    RegistrationVerifyRequest request,
  ) => _api.verifyRegistration(projectId, request);

  @override
  Future<Challenge> createProofChallenge(String projectId, String deviceId) =>
      _api.createProofChallenge(projectId, deviceId);

  @override
  Future<void> verifyProof(
    String projectId,
    String deviceId,
    ProofVerifyRequest request,
  ) => _api.verifyProof(projectId, deviceId, request);
}

DeviceRepository newDeviceRepository(GorapeApi api) =>
    DeviceRepositoryImpl(api);
