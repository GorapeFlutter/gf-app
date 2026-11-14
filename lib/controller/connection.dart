import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/connection.dart';
import '../entity/model/connection.dart';
import '../usecase/connection.dart';
import 'base.dart';

abstract interface class ConnectionController {
  /// GF-00151 — Handles save in ConnectionController.
  Future<void> save(ConnectionSettings settings);

  /// GF-00152 — Handles reset in ConnectionController.
  Future<void> reset();
}

final connectionConfigProvider = Provider<ConnectionConfig>(
  /* GF-00153 — Runs an inline callback in top level. */ (ref) =>
      newConnectionConfig(),
);

final connectionUsecaseProvider = Provider<ConnectionUsecase>(
  /* GF-00154 — Runs an inline callback in top level. */ (ref) =>
      newConnectionUsecase(
        ref.watch(secureStoreProvider),
        ref.watch(connectionConfigProvider),
      ),
);

/// GF-00011 — Loads and persists connection settings for API and OIDC access.
final class ConnectionControllerImpl extends AsyncNotifier<ConnectionSettings>
    implements ConnectionController {
  /// GF-00155 — Builds the widget or value for ConnectionControllerImpl.
  @override
  Future<ConnectionSettings> build() => ref
      .watch(connectionUsecaseProvider)
      .load(ref.watch(runtimePlatformProvider));

  /// GF-00156 — Handles save in ConnectionControllerImpl.
  @override
  Future<void> save(ConnectionSettings settings) async {
    await ref.read(connectionUsecaseProvider).save(settings);
    state = AsyncData(settings);
  }

  /// GF-00157 — Handles reset in ConnectionControllerImpl.
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
  /// GF-00158 — Handles check in ConnectionHealthController.
  Future<Map<String, dynamic>> check();
}

final class ConnectionHealthControllerImpl
    implements ConnectionHealthController {
  /// GF-00159 — Initializes ConnectionHealthControllerImpl.
  const ConnectionHealthControllerImpl(this._usecase);
  final ConnectionHealthUsecase _usecase;

  /// GF-00160 — Handles check in ConnectionHealthControllerImpl.
  /// GF-00011 — Checks whether the configured Gorape API endpoint is reachable.
  @override
  Future<Map<String, dynamic>> check() => _usecase.check();
}

/// GF-00161 — Creates an instance for new connection health controller.
ConnectionHealthController newConnectionHealthController(
  ConnectionHealthUsecase usecase,
) => ConnectionHealthControllerImpl(usecase);
