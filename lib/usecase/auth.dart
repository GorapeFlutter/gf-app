import '../repository/auth.dart';
import '../repository/secure_store.dart';
import '../entity/model/auth_session.dart';
import '../entity/model/auth_tokens.dart';
import '../share/error.dart';

abstract interface class AuthUsecase {
  /// GF-01045 — Computes AuthUsecase.isSupported.
  bool get isSupported;

  /// GF-01046 — Computes AuthUsecase.unsupportedReason.
  String? get unsupportedReason;

  /// GF-01047 — Handles restore in AuthUsecase.
  Future<AuthSession?> restore();

  /// GF-01048 — Handles sign in in AuthUsecase.
  Future<AuthSession> signIn({bool forceLogin = false});

  /// GF-01049 — Handles refresh in AuthUsecase.
  Future<AuthSession?> refresh(AuthSession current);

  /// GF-01050 — Handles sign out in AuthUsecase.
  Future<void> signOut(AuthSession? current);

  /// GF-01051 — Handles clear local session in AuthUsecase.
  Future<void> clearLocalSession();
}

final class AuthUsecaseImpl implements AuthUsecase {
  /// GF-01052 — Initializes AuthUsecaseImpl.
  AuthUsecaseImpl(this._repository, this._store);
  static const tokenStorageKey = 'gorape.auth_tokens';
  final AuthRepository _repository;
  final SecureStore _store;

  /// GF-01053 — Computes AuthUsecaseImpl.isSupported.
  @override
  bool get isSupported => _repository.isSupported;

  /// GF-01054 — Computes AuthUsecaseImpl.unsupportedReason.
  @override
  String? get unsupportedReason => _repository.unsupportedReason;

  /// GF-01055 — Handles restore in AuthUsecaseImpl.
  @override
  Future<AuthSession?> restore() async {
    // GF-02000 — Read and decode the locally persisted token set.
    final raw = await _store.read(tokenStorageKey);
    if (raw == null) return null;
    AuthTokens tokens;
    try {
      tokens = AuthTokens.decode(raw);
    } on FormatException {
      // GF-02001 — Remove malformed session data so it cannot be restored again.
      await _store.delete(tokenStorageKey);
      return null;
    }
    // GF-02002 — Reuse the session directly while its access token is valid.
    if (!tokens.isExpired()) return AuthSession(tokens: tokens);
    if (_repository.isSupported && tokens.canRefresh) {
      try {
        // GF-02003 — Refresh an expired session and persist the replacement.
        final refreshed = await _repository.refresh(tokens);
        await _store.write(tokenStorageKey, refreshed.encode());
        return AuthSession(tokens: refreshed);
      } on AppException {
        // Invalid sessions are cleared below.
      }
    }
    // GF-02004 — Clear expired sessions that could not be refreshed.
    await _store.delete(tokenStorageKey);
    return null;
  }

  /// GF-01056 — Handles sign in in AuthUsecaseImpl.
  @override
  Future<AuthSession> signIn({bool forceLogin = false}) async {
    // GF-02005 — Reject OIDC sign-in on platforms without an adapter.
    if (!_repository.isSupported) {
      throw OidcUnsupportedException(
        _repository.unsupportedReason ?? 'このプラットフォームではOIDCを利用できません。',
      );
    }
    // GF-02006 — Complete Authorization Code + PKCE with the identity provider.
    final tokens = await _repository.signIn(forceLogin: forceLogin);
    // GF-02007 — Persist tokens before exposing the authenticated session.
    await _store.write(tokenStorageKey, tokens.encode());
    return AuthSession(tokens: tokens);
  }

  /// GF-01057 — Handles refresh in AuthUsecaseImpl.
  @override
  Future<AuthSession?> refresh(AuthSession current) async {
    // GF-02008 — Skip refresh when the platform or refresh token is unavailable.
    if (!_repository.isSupported || !current.tokens.canRefresh) return null;
    try {
      // GF-02009 — Refresh tokens and persist the replacement session.
      final tokens = await _repository.refresh(current.tokens);
      await _store.write(tokenStorageKey, tokens.encode());
      return AuthSession(tokens: tokens);
    } on AppException {
      return null;
    }
  }

  /// GF-01058 — Handles sign out in AuthUsecaseImpl.
  @override
  Future<void> signOut(AuthSession? current) async {
    // GF-02010 — Attempt provider logout when a supported remote session exists.
    if (current != null && _repository.isSupported) {
      await _repository.signOut(current.tokens);
    }
    // GF-02011 — Always clear the local session after remote logout handling.
    await clearLocalSession();
  }

  /// GF-01059 — Handles clear local session in AuthUsecaseImpl.
  @override
  Future<void> clearLocalSession() => _store.delete(tokenStorageKey);
}

/// GF-01060 — Creates an instance for new auth usecase.
AuthUsecase newAuthUsecase(AuthRepository repository, SecureStore store) =>
    AuthUsecaseImpl(repository, store);
