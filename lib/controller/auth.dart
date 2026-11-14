import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../entity/model/auth_session.dart';
import '../entity/model/auth_support.dart';
import '../repository/auth.dart';
import '../share/error.dart';
import '../usecase/auth.dart';
import 'base.dart';
import 'connection.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  /* GF-00127 — Runs an inline callback in top level. */ (ref) {
    final platform = ref.watch(runtimePlatformProvider);
    final settings =
        ref.watch(connectionSettingsProvider).value ??
        ref.watch(connectionConfigProvider).defaultsFromEnvironment(platform);
    final client = http.Client();
    ref.onDispose(client.close);
    return newAuthRepository(settings, platform, httpClient: client);
  },
);

final authUsecaseProvider = Provider<AuthUsecase>(
  /* GF-00128 — Runs an inline callback in top level. */ (ref) =>
      newAuthUsecase(
        ref.watch(authRepositoryProvider),
        ref.watch(secureStoreProvider),
      ),
);

final authSupportProvider = Provider<AuthSupport>(
  /* GF-00129 — Runs an inline callback in top level. */ (ref) {
    final usecase = ref.watch(authUsecaseProvider);
    return AuthSupport(
      isSupported: usecase.isSupported,
      unsupportedReason: usecase.unsupportedReason,
    );
  },
);

abstract interface class AuthController {
  /// GF-00130 — Handles sign in in AuthController.
  Future<void> signIn({bool forceLogin = false});

  /// GF-00131 — Handles refresh session in AuthController.
  Future<bool> refreshSession();

  /// GF-00132 — Handles sign out in AuthController.
  Future<void> signOut();

  /// GF-00133 — Handles clear local session in AuthController.
  Future<void> clearLocalSession();

  /// GF-00134 — Handles handle unauthorized in AuthController.
  Future<void> handleUnauthorized();
}

final class AuthControllerImpl extends AsyncNotifier<AuthSession?>
    implements AuthController {
  Future<bool>? _refreshInFlight;

  /// GF-00135 — Builds the widget or value for AuthControllerImpl.
  /// GF-00001 — Loads connection settings before restoring the saved session.
  @override
  Future<AuthSession?> build() async {
    await ref.watch(connectionSettingsProvider.future);
    return ref.watch(authUsecaseProvider).restore();
  }

  /// GF-00136 — Handles sign in in AuthControllerImpl.
  /// GF-00002 — Starts OIDC sign-in and stores the resulting session state.
  @override
  Future<void> signIn({bool forceLogin = false}) async {
    // GF-02155 — Enter loading state before starting the provider interaction.
    state = const AsyncLoading();
    try {
      // GF-02156 — Call the use case and publish the restored session.
      state = AsyncData(
        await ref.read(authUsecaseProvider).signIn(forceLogin: forceLogin),
      );
    } on AppException catch (error, stackTrace) {
      // GF-02157 — Preserve expected application errors for the UI.
      state = AsyncError(error, stackTrace);
    } on Object catch (error, stackTrace) {
      // GF-02158 — Wrap unexpected provider errors as authentication failures.
      state = AsyncError(
        AuthException('ログインに失敗しました。', code: error.toString()),
        stackTrace,
      );
    }
  }

  /// GF-00137 — Handles refresh session in AuthControllerImpl.
  @override
  Future<bool> refreshSession() async {
    // GF-02159 — Reuse an in-flight refresh to prevent duplicate token requests.
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;
    // GF-02160 — Start one refresh and clear the in-flight marker afterward.
    final future = _refreshSession();
    _refreshInFlight = future;
    try {
      return await future;
    } finally {
      _refreshInFlight = null;
    }
  }

  /// GF-00138 — Handles refresh session in AuthControllerImpl.
  Future<bool> _refreshSession() async {
    final current = state.value;
    if (current == null) return false;
    final refreshed = await ref.read(authUsecaseProvider).refresh(current);
    if (refreshed == null) return false;
    state = AsyncData(refreshed);
    return true;
  }

  /// GF-00139 — Handles sign out in AuthControllerImpl.
  /// GF-00002 — Ends the remote and local session, then clears auth state.
  @override
  Future<void> signOut() async {
    await ref.read(authUsecaseProvider).signOut(state.value);
    state = const AsyncData(null);
  }

  /// GF-00140 — Handles clear local session in AuthControllerImpl.
  @override
  Future<void> clearLocalSession() async {
    await ref.read(authUsecaseProvider).clearLocalSession();
    state = const AsyncData(null);
  }

  /// GF-00141 — Handles handle unauthorized in AuthControllerImpl.
  @override
  Future<void> handleUnauthorized() async {
    // GF-02161 — Clear rejected credentials before publishing the auth error.
    await ref.read(authUsecaseProvider).clearLocalSession();
    state = AsyncError(
      const AuthException(
        'Gorapeがアクセストークンを拒否しました。もう一度ログインしてください。',
        code: 'access_token_rejected',
        guidance: 'KeycloakのIssuerとGorapeプロジェクトのoidc_issuerが一致しているか確認してください。',
      ),
      StackTrace.current,
    );
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthControllerImpl, AuthSession?>(
      AuthControllerImpl.new,
    );

/// Whether a session exists, without exposing access-token refreshes as an
/// authentication change to data providers.
final isAuthenticatedProvider = Provider<bool>(
  /* GF-00142 — Runs an inline callback in top level. */ (ref) => ref.watch(
    authControllerProvider.select(
      /* GF-00143 — Runs an inline callback in top level.callback. */ (
        session,
      ) => session.value != null,
    ),
  ),
);

final accessTokenProvider = Provider<String? Function()>(
  /* GF-00144 — Runs an inline callback in top level. */ (ref) =>
      /* GF-00145 — Runs an inline callback in top level.callback. */ () =>
          ref.read(authControllerProvider).value?.tokens.accessToken,
);
