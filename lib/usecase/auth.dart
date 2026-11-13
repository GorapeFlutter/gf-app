import '../repository/auth.dart';
import '../repository/secure_store.dart';
import '../entity/model/auth_session.dart';
import '../entity/model/auth_tokens.dart';
import '../share/error.dart';

abstract interface class AuthUsecase {
  bool get isSupported;
  String? get unsupportedReason;
  Future<AuthSession?> restore();
  Future<AuthSession> signIn({bool forceLogin = false});
  Future<AuthSession?> refresh(AuthSession current);
  Future<void> signOut(AuthSession? current);
  Future<void> clearLocalSession();
}

final class AuthUsecaseImpl implements AuthUsecase {
  AuthUsecaseImpl(this._repository, this._store);
  static const tokenStorageKey = 'gorape.auth_tokens';
  final AuthRepository _repository;
  final SecureStore _store;

  @override
  bool get isSupported => _repository.isSupported;
  @override
  String? get unsupportedReason => _repository.unsupportedReason;

  @override
  Future<AuthSession?> restore() async {
    final raw = await _store.read(tokenStorageKey);
    if (raw == null) return null;
    AuthTokens tokens;
    try {
      tokens = AuthTokens.decode(raw);
    } on FormatException {
      await _store.delete(tokenStorageKey);
      return null;
    }
    if (!tokens.isExpired()) return AuthSession(tokens: tokens);
    if (_repository.isSupported && tokens.canRefresh) {
      try {
        final refreshed = await _repository.refresh(tokens);
        await _store.write(tokenStorageKey, refreshed.encode());
        return AuthSession(tokens: refreshed);
      } on AppException {
        // Invalid sessions are cleared below.
      }
    }
    await _store.delete(tokenStorageKey);
    return null;
  }

  @override
  Future<AuthSession> signIn({bool forceLogin = false}) async {
    if (!_repository.isSupported) {
      throw OidcUnsupportedException(
        _repository.unsupportedReason ?? 'このプラットフォームではOIDCを利用できません。',
      );
    }
    final tokens = await _repository.signIn(forceLogin: forceLogin);
    await _store.write(tokenStorageKey, tokens.encode());
    return AuthSession(tokens: tokens);
  }

  @override
  Future<AuthSession?> refresh(AuthSession current) async {
    if (!_repository.isSupported || !current.tokens.canRefresh) return null;
    try {
      final tokens = await _repository.refresh(current.tokens);
      await _store.write(tokenStorageKey, tokens.encode());
      return AuthSession(tokens: tokens);
    } on AppException {
      return null;
    }
  }

  @override
  Future<void> signOut(AuthSession? current) async {
    if (current != null && _repository.isSupported) {
      await _repository.signOut(current.tokens);
    }
    await clearLocalSession();
  }

  @override
  Future<void> clearLocalSession() => _store.delete(tokenStorageKey);
}

AuthUsecase newAuthUsecase(AuthRepository repository, SecureStore store) =>
    AuthUsecaseImpl(repository, store);
