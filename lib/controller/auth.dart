import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../entity/model/auth_session.dart';
import '../entity/model/auth_support.dart';
import '../repository/auth.dart';
import '../share/error.dart';
import '../usecase/auth.dart';
import 'base.dart';
import 'connection.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final platform = ref.watch(runtimePlatformProvider);
  final settings =
      ref.watch(connectionSettingsProvider).value ??
      ref.watch(connectionConfigProvider).defaultsFromEnvironment(platform);
  final client = http.Client();
  ref.onDispose(client.close);
  return newAuthRepository(settings, platform, httpClient: client);
});

final authUsecaseProvider = Provider<AuthUsecase>(
  (ref) => newAuthUsecase(
    ref.watch(authRepositoryProvider),
    ref.watch(secureStoreProvider),
  ),
);

final authSupportProvider = Provider<AuthSupport>((ref) {
  final usecase = ref.watch(authUsecaseProvider);
  return AuthSupport(
    isSupported: usecase.isSupported,
    unsupportedReason: usecase.unsupportedReason,
  );
});

abstract interface class AuthController {
  Future<void> signIn({bool forceLogin = false});
  Future<bool> refreshSession();
  Future<void> signOut();
  Future<void> clearLocalSession();
  Future<void> handleUnauthorized();
}

final class AuthControllerImpl extends AsyncNotifier<AuthSession?>
    implements AuthController {
  Future<bool>? _refreshInFlight;

  @override
  Future<AuthSession?> build() async {
    await ref.watch(connectionSettingsProvider.future);
    return ref.watch(authUsecaseProvider).restore();
  }

  @override
  Future<void> signIn({bool forceLogin = false}) async {
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await ref.read(authUsecaseProvider).signIn(forceLogin: forceLogin),
      );
    } on AppException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    } on Object catch (error, stackTrace) {
      state = AsyncError(
        AuthException('ログインに失敗しました。', code: error.toString()),
        stackTrace,
      );
    }
  }

  @override
  Future<bool> refreshSession() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;
    final future = _refreshSession();
    _refreshInFlight = future;
    try {
      return await future;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<bool> _refreshSession() async {
    final current = state.value;
    if (current == null) return false;
    final refreshed = await ref.read(authUsecaseProvider).refresh(current);
    if (refreshed == null) return false;
    state = AsyncData(refreshed);
    return true;
  }

  @override
  Future<void> signOut() async {
    await ref.read(authUsecaseProvider).signOut(state.value);
    state = const AsyncData(null);
  }

  @override
  Future<void> clearLocalSession() async {
    await ref.read(authUsecaseProvider).clearLocalSession();
    state = const AsyncData(null);
  }

  @override
  Future<void> handleUnauthorized() async {
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
  (ref) => ref.watch(
    authControllerProvider.select((session) => session.value != null),
  ),
);

final accessTokenProvider = Provider<String? Function()>(
  (ref) =>
      () => ref.read(authControllerProvider).value?.tokens.accessToken,
);
