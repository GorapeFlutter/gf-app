import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session.dart';
import '../auth/auth_tokens.dart';
import '../auth/oidc_service.dart';
import '../auth/oidc_service_factory.dart';
import '../core/config/connection_settings.dart';
import '../core/config/runtime_platform.dart';
import '../core/errors/app_exception.dart';
import '../core/storage/secure_store.dart';

final runtimePlatformProvider = Provider<RuntimePlatform>(
  (ref) => RuntimePlatform.current(),
);

final secureStoreProvider = Provider<SecureStore>(
  (ref) => FlutterSecureStore(),
);

class ConnectionSettingsController extends AsyncNotifier<ConnectionSettings> {
  static const storageKey = 'gorape.connection_settings';

  @override
  Future<ConnectionSettings> build() async {
    final platform = ref.watch(runtimePlatformProvider);
    final defaults = ConnectionSettings.defaultsFromEnvironment(platform);
    final raw = await ref.watch(secureStoreProvider).read(storageKey);
    if (raw == null) return defaults;
    try {
      final stored = ConnectionSettings.decode(raw);
      return stored.scopes.contains('openid') ? stored : defaults;
    } on FormatException {
      return defaults;
    }
  }

  Future<void> save(ConnectionSettings settings) async {
    final errors = settings.validate();
    if (errors.isNotEmpty) {
      throw ConfigurationException(
        errors.join('\n'),
        code: 'invalid_connection_settings',
      );
    }
    await ref.read(secureStoreProvider).write(storageKey, settings.encode());
    state = AsyncData(settings);
  }

  Future<void> reset() async {
    await ref.read(secureStoreProvider).delete(storageKey);
    final platform = ref.read(runtimePlatformProvider);
    state = AsyncData(ConnectionSettings.defaultsFromEnvironment(platform));
  }
}

final connectionSettingsProvider =
    AsyncNotifierProvider<ConnectionSettingsController, ConnectionSettings>(
      ConnectionSettingsController.new,
    );

final oidcServiceProvider = Provider<OidcService>((ref) {
  final platform = ref.watch(runtimePlatformProvider);
  final settings =
      ref.watch(connectionSettingsProvider).value ??
      ConnectionSettings.defaultsFromEnvironment(platform);
  return createOidcService(settings, platform);
});

class AuthController extends AsyncNotifier<AuthSession?> {
  static const tokenStorageKey = 'gorape.auth_tokens';

  OidcService? _oidc;
  Future<bool>? _refreshInFlight;

  @override
  Future<AuthSession?> build() async {
    final settings = await ref.watch(connectionSettingsProvider.future);
    final oidc = ref.watch(oidcServiceProvider);
    _oidc = oidc;

    if (!oidc.isSupported) {
      // Keep a local session if one exists, but the UI will explain that a new
      // login is impossible on this platform.
      return _restore(settings, oidc, allowRefresh: false);
    }
    return _restore(settings, oidc, allowRefresh: true);
  }

  Future<AuthSession?> _restore(
    ConnectionSettings settings,
    OidcService oidc, {
    required bool allowRefresh,
  }) async {
    final store = ref.read(secureStoreProvider);
    final raw = await store.read(tokenStorageKey);
    if (raw == null) return null;
    AuthTokens tokens;
    try {
      tokens = AuthTokens.decode(raw);
    } on FormatException {
      await store.delete(tokenStorageKey);
      return null;
    }

    if (tokens.isExpired()) {
      if (allowRefresh && tokens.canRefresh && oidc.isSupported) {
        try {
          final refreshed = await oidc.refresh(tokens);
          await store.write(tokenStorageKey, refreshed.encode());
          return AuthSession(tokens: refreshed);
        } on AppException {
          await store.delete(tokenStorageKey);
          return null;
        }
      }
      await store.delete(tokenStorageKey);
      return null;
    }
    return AuthSession(tokens: tokens);
  }

  Future<void> signIn() async {
    final OidcService oidc = _oidc ?? ref.read(oidcServiceProvider);
    if (!oidc.isSupported) {
      state = AsyncError(
        OidcUnsupportedException(
          oidc.unsupportedReason ?? 'このプラットフォームではOIDCを利用できません。',
        ),
        StackTrace.current,
      );
      return;
    }
    state = const AsyncLoading();
    try {
      final tokens = await oidc.signIn();
      await ref
          .read(secureStoreProvider)
          .write(tokenStorageKey, tokens.encode());
      state = AsyncData(AuthSession(tokens: tokens));
    } on AppException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    } on Object catch (error, stackTrace) {
      state = AsyncError(
        AuthException('ログインに失敗しました。', code: error.toString()),
        stackTrace,
      );
    }
  }

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
    final OidcService oidc = _oidc ?? ref.read(oidcServiceProvider);
    if (!oidc.isSupported || !current.tokens.canRefresh) return false;
    try {
      final refreshed = await oidc.refresh(current.tokens);
      await ref
          .read(secureStoreProvider)
          .write(tokenStorageKey, refreshed.encode());
      state = AsyncData(AuthSession(tokens: refreshed));
      return true;
    } on AppException {
      return false;
    }
  }

  Future<void> signOut() async {
    final current = state.value;
    final OidcService oidc = _oidc ?? ref.read(oidcServiceProvider);
    if (current != null && oidc.isSupported) {
      await oidc.signOut(current.tokens);
    }
    await ref.read(secureStoreProvider).delete(tokenStorageKey);
    state = const AsyncData(null);
  }

  /// Clears local tokens without starting a Keycloak end-session browser flow.
  Future<void> clearLocalSession() async {
    await ref.read(secureStoreProvider).delete(tokenStorageKey);
    state = const AsyncData(null);
  }

  /// Called when Gorape rejects the access token.
  Future<void> handleUnauthorized() async {
    await ref.read(secureStoreProvider).delete(tokenStorageKey);
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
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

final accessTokenProvider = Provider<String? Function()>((ref) {
  return () => ref.read(authControllerProvider).value?.tokens.accessToken;
});
