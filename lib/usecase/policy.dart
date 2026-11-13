import '../repository/policy.dart';
import '../entity/model/policy.dart';

abstract interface class DevicePolicyUsecase {
  PolicyCapabilities get capabilities;
  Future<LocalDevicePolicy> load();
  Future<void> save(LocalDevicePolicy policy);
}

final class DevicePolicyUsecaseImpl implements DevicePolicyUsecase {
  const DevicePolicyUsecaseImpl(this._repository);
  final DevicePolicyRepository _repository;

  @override
  PolicyCapabilities get capabilities => _repository.capabilities;
  @override
  Future<LocalDevicePolicy> load() => _repository.load();
  @override
  Future<void> save(LocalDevicePolicy policy) => _repository.save(policy);
}

DevicePolicyUsecase newDevicePolicyUsecase(DevicePolicyRepository repository) =>
    DevicePolicyUsecaseImpl(repository);
