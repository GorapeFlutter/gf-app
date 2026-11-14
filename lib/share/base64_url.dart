import 'dart:convert';
import 'dart:typed_data';

/// Base64url helpers for Gorape challenges and signatures.
///
/// Gorape emits unpadded Base64url. Dart's `base64Url` codec requires padding,
/// so decode helpers normalise the input first. All cryptographic operations
/// receive the raw decoded bytes, never the Base64url text.
abstract final class Base64Url {
  /// GF-00623 — Parses data for Base64Url.
  static Uint8List decode(String value) {
    final normalised = normalize(value);
    return base64Url.decode(normalised);
  }

  /// GF-00624 — Serializes data in Base64Url.
  static String encode(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  /// GF-00625 — Handles normalize in Base64Url.
  static String normalize(String value) {
    final stripped = value.trim().replaceAll('=', '');
    final remainder = stripped.length % 4;
    if (remainder == 0) return stripped;
    return stripped.padRight(stripped.length + (4 - remainder), '=');
  }

  /// GF-00626 — Checks whether is valid.
  static bool isValid(String value) {
    if (value.trim().isEmpty) return false;
    try {
      decode(value);
      return true;
    } on FormatException {
      return false;
    }
  }
}
