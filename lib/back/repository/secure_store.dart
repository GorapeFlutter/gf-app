import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal storage contract so tests and previews never touch the platform
/// keychain.
abstract interface class SecureStore {
  /// GF-00611 — Handles read in SecureStore.
  Future<String?> read(String key);

  /// GF-00612 — Handles write in SecureStore.
  Future<void> write(String key, String value);

  /// GF-00613 — Handles delete in SecureStore.
  Future<void> delete(String key);
}

/// GF-00614 — Creates an instance for new secure store.
/// Creates the production secure-storage repository.
SecureStore newSecureStore() => FlutterSecureStore();

class FlutterSecureStore implements SecureStore {
  /// GF-00615 — Initializes FlutterSecureStore.
  FlutterSecureStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
            mOptions: MacOsOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  /// GF-00616 — Handles read in FlutterSecureStore.
  @override
  Future<String?> read(String key) => _storage.read(key: key);

  /// GF-00617 — Handles write in FlutterSecureStore.
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  /// GF-00618 — Handles delete in FlutterSecureStore.
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class MemorySecureStore implements SecureStore {
  /// GF-00619 — Initializes MemorySecureStore.
  MemorySecureStore([Map<String, String>? seed]) : values = {...?seed};

  final Map<String, String> values;

  /// GF-00620 — Handles read in MemorySecureStore.
  @override
  Future<String?> read(String key) async => values[key];

  /// GF-00621 — Handles write in MemorySecureStore.
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  /// GF-00622 — Handles delete in MemorySecureStore.
  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
