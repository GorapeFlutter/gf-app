import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/connection.dart';
import '../entity/model/connection.dart';
import '../usecase/connection.dart';
import 'base.dart';

abstract interface class ConnectionController {
  Future<void> save(ConnectionSettings settings);
  Future<void> reset();
}

final connectionConfigProvider = Provider<ConnectionConfig>(
  (ref) => newConnectionConfig(),
);

final connectionUsecaseProvider = Provider<ConnectionUsecase>(
  (ref) => newConnectionUsecase(
    ref.watch(secureStoreProvider),
    ref.watch(connectionConfigProvider),
  ),
);

final class ConnectionControllerImpl extends AsyncNotifier<ConnectionSettings>
    implements ConnectionController {
  @override
  Future<ConnectionSettings> build() => ref
      .watch(connectionUsecaseProvider)
      .load(ref.watch(runtimePlatformProvider));

  @override
  Future<void> save(ConnectionSettings settings) async {
    await ref.read(connectionUsecaseProvider).save(settings);
    state = AsyncData(settings);
  }

  @override
  Future<void> reset() async {
    final settings = await ref
        .read(connectionUsecaseProvider)
        .reset(ref.read(runtimePlatformProvider));
    state = AsyncData(settings);
  }
}

final connectionSettingsProvider =
    AsyncNotifierProvider<ConnectionControllerImpl, ConnectionSettings>(
      ConnectionControllerImpl.new,
    );

abstract interface class ConnectionHealthController {
  Future<Map<String, dynamic>> check();
}

final class ConnectionHealthControllerImpl
    implements ConnectionHealthController {
  const ConnectionHealthControllerImpl(this._usecase);
  final ConnectionHealthUsecase _usecase;

  @override
  Future<Map<String, dynamic>> check() => _usecase.check();
}

ConnectionHealthController newConnectionHealthController(
  ConnectionHealthUsecase usecase,
) => ConnectionHealthControllerImpl(usecase);
