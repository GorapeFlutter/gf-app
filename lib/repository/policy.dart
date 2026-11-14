import '../entity/model/policy.dart';
import 'secure_store.dart';

/// Persistence boundary for local-only device policy preferences.
abstract interface class DevicePolicyRepository {
  /// GF-00583 — Computes DevicePolicyRepository.capabilities.
  PolicyCapabilities get capabilities;

  /// GF-00584 — Handles load in DevicePolicyRepository.
  Future<LocalDevicePolicy> load();

  /// GF-00585 — Handles save in DevicePolicyRepository.
  Future<void> save(LocalDevicePolicy policy);
}

final class DevicePolicyRepositoryImpl implements DevicePolicyRepository {
  /// GF-00586 — Initializes DevicePolicyRepositoryImpl.
  DevicePolicyRepositoryImpl(this._store);

  static const _key = 'gorape.device_policy';
  final SecureStore _store;

  /// GF-00587 — Computes DevicePolicyRepositoryImpl.capabilities.
  @override
  PolicyCapabilities get capabilities => PolicyCapabilities.none;

  /// GF-00588 — Handles load in DevicePolicyRepositoryImpl.
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

  /// GF-00589 — Handles save in DevicePolicyRepositoryImpl.
  @override
  Future<void> save(LocalDevicePolicy policy) =>
      _store.write(_key, policy.encode());
}

/// GF-00590 — Creates an instance for new device policy repository.
DevicePolicyRepository newDevicePolicyRepository(SecureStore store) =>
    DevicePolicyRepositoryImpl(store);
