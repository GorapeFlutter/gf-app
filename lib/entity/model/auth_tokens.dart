import 'dart:convert';

/// Tokens obtained from Keycloak.
///
/// Only [accessToken] is used as an API credential. [idToken] exists for
/// logout hints and local display, never for Gorape API authentication.
class AuthTokens {
  /// GF-00261 — Initializes AuthTokens.
  const AuthTokens({
    required this.accessToken,
    this.idToken,
    this.refreshToken,
    this.expiresAt,
    this.scopes = const [],
  });

  final String accessToken;
  final String? idToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final List<String> scopes;

  /// GF-00262 — Checks whether is expired.
  bool isExpired({Duration skew = const Duration(seconds: 30)}) {
    final expiry = expiresAt;
    if (expiry == null) return false;
    return DateTime.now().add(skew).isAfter(expiry);
  }

  /// GF-00263 — Computes AuthTokens.canRefresh.
  bool get canRefresh => refreshToken != null && refreshToken!.isNotEmpty;

  /// GF-00264 — Serializes data in AuthTokens.
  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'id_token': idToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt?.toUtc().toIso8601String(),
    'scopes': scopes,
  };

  /// GF-00265 — Initializes AuthTokens.fromJson.
  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final accessToken = json['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const FormatException('Missing access token');
    }
    return AuthTokens(
      accessToken: accessToken,
      idToken: json['id_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
      scopes:
          (json['scopes'] as List<dynamic>?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
    );
  }

  /// GF-00266 — Serializes data in AuthTokens.
  String encode() => jsonEncode(toJson());

  /// GF-00267 — Initializes AuthTokens.decode.
  factory AuthTokens.decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid token payload');
    }
    return AuthTokens.fromJson(decoded);
  }
}
