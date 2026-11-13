import '../core/config/connection_settings.dart';
import 'auth_tokens.dart';

/// Platform OIDC adapter.
abstract interface class OidcService {
  bool get isSupported;

  String? get unsupportedReason;

  Future<AuthTokens> signIn();

  Future<AuthTokens> refresh(AuthTokens tokens);

  Future<void> signOut(AuthTokens tokens);
}

class UnsupportedOidcService implements OidcService {
  const UnsupportedOidcService(this.unsupportedReason);

  @override
  final String? unsupportedReason;

  @override
  bool get isSupported => false;

  @override
  Future<AuthTokens> signIn() {
    throw StateError('OIDC is not supported on this platform');
  }

  @override
  Future<AuthTokens> refresh(AuthTokens tokens) {
    throw StateError('OIDC is not supported on this platform');
  }

  @override
  Future<void> signOut(AuthTokens tokens) async {}
}

/// Builds the correct OIDC adapter for the platform.
typedef OidcServiceFactory =
    OidcService Function(ConnectionSettings settings, String platform);
