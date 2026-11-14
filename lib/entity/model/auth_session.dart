import '../../share/jwt.dart';
import 'auth_tokens.dart';

/// A locally held, server-validated session.
///
/// Claims are decoded without verification for display only. Gorape makes the
/// actual authorization decision from the access token.
class AuthSession {
  /// GF-00252 — Initializes AuthSession.
  const AuthSession({required this.tokens});

  final AuthTokens tokens;

  /// GF-00253 — Computes AuthSession.claims.
  Map<String, dynamic> get claims =>
      JwtClaims.decodeUnverified(tokens.accessToken);

  /// GF-00254 — Computes AuthSession.subject.
  String get subject => _claim('sub') ?? 'unknown';

  /// GF-00255 — Computes AuthSession.displayName.
  String get displayName =>
      _claim('name') ??
      _claim('preferred_username') ??
      _claim('email') ??
      subject;

  /// GF-00256 — Computes AuthSession.username.
  String? get username => _claim('preferred_username');

  /// GF-00257 — Computes AuthSession.email.
  String? get email => _claim('email');

  /// GF-00258 — Computes AuthSession.issuer.
  String? get issuer => _claim('iss');

  /// GF-00259 — Handles claim in AuthSession.
  String? _claim(String name) {
    final value = claims[name];
    return value is String && value.isNotEmpty ? value : null;
  }
}
