import 'gorape.dart';

abstract interface class ConnectionRepository {
  Future<Map<String, dynamic>> health();
}

final class ConnectionRepositoryImpl implements ConnectionRepository {
  const ConnectionRepositoryImpl(this._api);

  final GorapeApi _api;

  @override
  Future<Map<String, dynamic>> health() => _api.health();
}

ConnectionRepository newConnectionRepository(GorapeApi api) =>
    ConnectionRepositoryImpl(api);
