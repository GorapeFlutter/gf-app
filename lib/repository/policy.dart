import '../entity/model/policy.dart';
import 'secure_store.dart';

/// Persistence boundary for local-only device policy preferences.
abstract interface class DevicePolicyRepository {
  PolicyCapabilities get capabilities;

  Future<LocalDevicePolicy> load();

  Future<void> save(LocalDevicePolicy policy);
}

final class DevicePolicyRepositoryImpl implements DevicePolicyRepository {
  DevicePolicyRepositoryImpl(this._store);

  static const _key = 'gorape.device_policy';
  final SecureStore _store;

  @override
  PolicyCapabilities get capabilities => PolicyCapabilities.none;

  @override
  Future<LocalDevicePolicy> load() async {
    final raw = await _store.read(_key);
    if (raw == null) return const LocalDevicePolicy();
    try {
      return LocalDevicePolicy.decode(raw);
    } on FormatException {
      return const LocalDevicePolicy();
    }
  }

  @override
  Future<void> save(LocalDevicePolicy policy) =>
      _store.write(_key, policy.encode());
}

DevicePolicyRepository newDevicePolicyRepository(SecureStore store) =>
    DevicePolicyRepositoryImpl(store);
