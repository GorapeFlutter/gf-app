import '../config/connection.dart';
import '../entity/model/connection.dart';
import '../entity/model/platform.dart';
import '../repository/connection.dart';
import '../repository/secure_store.dart';
import '../share/error.dart';

abstract interface class ConnectionUsecase {
  /// GF-01061 — Handles load in ConnectionUsecase.
  Future<ConnectionSettings> load(RuntimePlatform platform);

  /// GF-01062 — Handles save in ConnectionUsecase.
  Future<void> save(ConnectionSettings settings);

  /// GF-01063 — Handles reset in ConnectionUsecase.
  Future<ConnectionSettings> reset(RuntimePlatform platform);
}

final class ConnectionUsecaseImpl implements ConnectionUsecase {
  /// GF-01064 — Initializes ConnectionUsecaseImpl.
  ConnectionUsecaseImpl(this._store, this._config);
  static const storageKey = 'gorape.connection_settings';
  final SecureStore _store;
  final ConnectionConfig _config;

  /// GF-01065 — Handles load in ConnectionUsecaseImpl.
  @override
  Future<ConnectionSettings> load(RuntimePlatform platform) async {
    // GF-02066 — Start from platform-specific runtime defaults.
    final defaults = _config.defaultsFromEnvironment(platform);
    // GF-02067 — Prefer locally saved settings when they can be decoded.
    final raw = await _store.read(storageKey);
    if (raw == null) return defaults;
    try {
      final stored = ConnectionSettings.decode(raw);
      // GF-02068 — Reject saved settings that omit the required OIDC scope.
      return stored.scopes.contains('openid') ? stored : defaults;
    } on FormatException {
      return defaults;
    }
  }

  /// GF-01066 — Handles save in ConnectionUsecaseImpl.
  @override
  Future<void> save(ConnectionSettings settings) async {
    // GF-02069 — Validate all URLs and OIDC fields before persistence.
    final errors = settings.validate();
    if (errors.isNotEmpty) {
      throw ConfigurationException(
        errors.join('\n'),
        code: 'invalid_connection_settings',
      );
    }
    // GF-02070 — Persist the validated connection configuration securely.
    await _store.write(storageKey, settings.encode());
  }

  /// GF-01067 — Handles reset in ConnectionUsecaseImpl.
  @override
  Future<ConnectionSettings> reset(RuntimePlatform platform) async {
    // GF-02071 — Remove overrides and return the platform defaults.
    await _store.delete(storageKey);
    return _config.defaultsFromEnvironment(platform);
  }
}

/// GF-01068 — Creates an instance for new connection usecase.
ConnectionUsecase newConnectionUsecase(
  SecureStore store,
  ConnectionConfig config,
) => ConnectionUsecaseImpl(store, config);

abstract interface class ConnectionHealthUsecase {
  /// GF-01069 — Handles check in ConnectionHealthUsecase.
  Future<Map<String, dynamic>> check();
}

final class ConnectionHealthUsecaseImpl implements ConnectionHealthUsecase {
  /// GF-01070 — Initializes ConnectionHealthUsecaseImpl.
  const ConnectionHealthUsecaseImpl(this._repository);
  final ConnectionRepository _repository;

  /// GF-01071 — Handles check in ConnectionHealthUsecaseImpl.
  @override
  Future<Map<String, dynamic>> check() => _repository.health();
}

/// GF-01072 — Creates an instance for new connection health usecase.
ConnectionHealthUsecase newConnectionHealthUsecase(
  ConnectionRepository repository,
) => ConnectionHealthUsecaseImpl(repository);
