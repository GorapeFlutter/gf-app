import '../repository/policy.dart';
import '../entity/model/policy.dart';

abstract interface class DevicePolicyUsecase {
  /// GF-01111 — Computes DevicePolicyUsecase.capabilities.
  PolicyCapabilities get capabilities;

  /// GF-01112 — Handles load in DevicePolicyUsecase.
  Future<LocalDevicePolicy> load();

  /// GF-01113 — Handles save in DevicePolicyUsecase.
  Future<void> save(LocalDevicePolicy policy);
}

final class DevicePolicyUsecaseImpl implements DevicePolicyUsecase {
  /// GF-01114 — Initializes DevicePolicyUsecaseImpl.
  const DevicePolicyUsecaseImpl(this._repository);
  final DevicePolicyRepository _repository;

  /// GF-01115 — Computes DevicePolicyUsecaseImpl.capabilities.
  @override
  PolicyCapabilities get capabilities => _repository.capabilities;

  /// GF-01116 — Handles load in DevicePolicyUsecaseImpl.
  @override
  Future<LocalDevicePolicy> load() => _repository.load();

  /// GF-01117 — Handles save in DevicePolicyUsecaseImpl.
  @override
  Future<void> save(LocalDevicePolicy policy) => _repository.save(policy);
}

/// GF-01118 — Creates an instance for new device policy usecase.
DevicePolicyUsecase newDevicePolicyUsecase(DevicePolicyRepository repository) =>
    DevicePolicyUsecaseImpl(repository);
