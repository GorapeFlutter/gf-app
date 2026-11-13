import '../config/connection.dart';
import '../entity/model/connection.dart';
import '../entity/model/platform.dart';
import '../repository/connection.dart';
import '../repository/secure_store.dart';
import '../share/error.dart';

abstract interface class ConnectionUsecase {
  Future<ConnectionSettings> load(RuntimePlatform platform);
  Future<void> save(ConnectionSettings settings);
  Future<ConnectionSettings> reset(RuntimePlatform platform);
}

final class ConnectionUsecaseImpl implements ConnectionUsecase {
  ConnectionUsecaseImpl(this._store, this._config);
  static const storageKey = 'gorape.connection_settings';
  final SecureStore _store;
  final ConnectionConfig _config;

  @override
  Future<ConnectionSettings> load(RuntimePlatform platform) async {
    final defaults = _config.defaultsFromEnvironment(platform);
    final raw = await _store.read(storageKey);
    if (raw == null) return defaults;
    try {
      final stored = ConnectionSettings.decode(raw);
      return stored.scopes.contains('openid') ? stored : defaults;
    } on FormatException {
      return defaults;
    }
  }

  @override
  Future<void> save(ConnectionSettings settings) async {
    final errors = settings.validate();
    if (errors.isNotEmpty) {
      throw ConfigurationException(
        errors.join('\n'),
        code: 'invalid_connection_settings',
      );
    }
    await _store.write(storageKey, settings.encode());
  }

  @override
  Future<ConnectionSettings> reset(RuntimePlatform platform) async {
    await _store.delete(storageKey);
    return _config.defaultsFromEnvironment(platform);
  }
}

ConnectionUsecase newConnectionUsecase(
  SecureStore store,
  ConnectionConfig config,
) => ConnectionUsecaseImpl(store, config);

abstract interface class ConnectionHealthUsecase {
  Future<Map<String, dynamic>> check();
}

final class ConnectionHealthUsecaseImpl implements ConnectionHealthUsecase {
  const ConnectionHealthUsecaseImpl(this._repository);
  final ConnectionRepository _repository;

  @override
  Future<Map<String, dynamic>> check() => _repository.health();
}

ConnectionHealthUsecase newConnectionHealthUsecase(
  ConnectionRepository repository,
) => ConnectionHealthUsecaseImpl(repository);
