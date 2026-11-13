import 'dart:convert';

/// Unverified JWT payload decoding for display only.
///
/// The app never treats these claims as an authorization decision; Gorape
/// validates the access token server-side. Signature verification is not
/// performed here on purpose (the client does not own the realm keys).
abstract final class JwtClaims {
  static Map<String, dynamic> decodeUnverified(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return const {};
    try {
      final payload = utf8.decode(base64Url.decode(_pad(parts[1])));
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on Object {
      return const {};
    }
  }

  static String _pad(String value) {
    final remainder = value.length % 4;
    if (remainder == 0) return value;
    return value.padRight(value.length + (4 - remainder), '=');
  }
}
