import '../core/utils/jwt.dart';
import 'auth_tokens.dart';

/// A locally held, server-validated session.
///
/// Claims are decoded without verification for display only. Gorape makes the
/// actual authorization decision from the access token.
class AuthSession {
  const AuthSession({required this.tokens});

  final AuthTokens tokens;

  Map<String, dynamic> get claims =>
      JwtClaims.decodeUnverified(tokens.accessToken);

  String get subject => _claim('sub') ?? 'unknown';

  String get displayName =>
      _claim('name') ??
      _claim('preferred_username') ??
      _claim('email') ??
      subject;

  String? get username => _claim('preferred_username');

  String? get email => _claim('email');

  String? get issuer => _claim('iss');

  String? _claim(String name) {
    final value = claims[name];
    return value is String && value.isNotEmpty ? value : null;
  }
}
