import '../entity/model/device.dart';
import '../entity/request/device.dart';
import '../entity/response/challenge.dart';
import 'gorape.dart';

abstract interface class DeviceRepository {
  /// GF-00437 — Handles list in DeviceRepository.
  Future<List<Device>> list(String projectId);

  /// GF-00438 — Handles get in DeviceRepository.
  Future<Device> get(String projectId, String deviceId);

  /// GF-00439 — Handles revoke in DeviceRepository.
  Future<void> revoke(String projectId, String deviceId);

  /// GF-00440 — Handles create registration challenge in DeviceRepository.
  Future<Challenge> createRegistrationChallenge(
    String projectId, {
    required String platform,
  });

  /// GF-00441 — Handles verify registration in DeviceRepository.
  Future<Device> verifyRegistration(
    String projectId,
    RegistrationVerifyRequest request,
  );

  /// GF-00442 — Handles create proof challenge in DeviceRepository.
  Future<Challenge> createProofChallenge(String projectId, String deviceId);

  /// GF-00443 — Handles verify proof in DeviceRepository.
  Future<void> verifyProof(
    String projectId,
    String deviceId,
    ProofVerifyRequest request,
  );
}

final class DeviceRepositoryImpl implements DeviceRepository {
  /// GF-00444 — Initializes DeviceRepositoryImpl.
  const DeviceRepositoryImpl(this._api);

  final GorapeApi _api;

  /// GF-00445 — Handles list in DeviceRepositoryImpl.
  @override
  Future<List<Device>> list(String projectId) => _api.listDevices(projectId);

  /// GF-00446 — Handles get in DeviceRepositoryImpl.
  @override
  Future<Device> get(String projectId, String deviceId) =>
      _api.getDevice(projectId, deviceId);

  /// GF-00447 — Handles revoke in DeviceRepositoryImpl.
  @override
  Future<void> revoke(String projectId, String deviceId) =>
      _api.revokeDevice(projectId, deviceId);

  /// GF-00448 — Handles create registration challenge in DeviceRepositoryImpl.
  @override
  Future<Challenge> createRegistrationChallenge(
    String projectId, {
    required String platform,
  }) => _api.createRegistrationChallenge(projectId, platform: platform);

  /// GF-00449 — Handles verify registration in DeviceRepositoryImpl.
  @override
  Future<Device> verifyRegistration(
    String projectId,
    RegistrationVerifyRequest request,
  ) => _api.verifyRegistration(projectId, request);

  /// GF-00450 — Handles create proof challenge in DeviceRepositoryImpl.
  @override
  Future<Challenge> createProofChallenge(String projectId, String deviceId) =>
      _api.createProofChallenge(projectId, deviceId);

  /// GF-00451 — Handles verify proof in DeviceRepositoryImpl.
  @override
  Future<void> verifyProof(
    String projectId,
    String deviceId,
    ProofVerifyRequest request,
  ) => _api.verifyProof(projectId, deviceId, request);
}

/// GF-00452 — Creates an instance for new device repository.
DeviceRepository newDeviceRepository(GorapeApi api) =>
    DeviceRepositoryImpl(api);
