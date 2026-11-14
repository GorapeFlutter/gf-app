import 'gorape.dart';

abstract interface class ConnectionRepository {
  /// GF-00433 — Handles health in ConnectionRepository.
  Future<Map<String, dynamic>> health();
}

final class ConnectionRepositoryImpl implements ConnectionRepository {
  /// GF-00434 — Initializes ConnectionRepositoryImpl.
  const ConnectionRepositoryImpl(this._api);

  final GorapeApi _api;

  /// GF-00435 — Handles health in ConnectionRepositoryImpl.
  @override
  Future<Map<String, dynamic>> health() => _api.health();
}

/// GF-00436 — Creates an instance for new connection repository.
ConnectionRepository newConnectionRepository(GorapeApi api) =>
    ConnectionRepositoryImpl(api);
