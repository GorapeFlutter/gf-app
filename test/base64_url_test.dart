import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/core/utils/base64_url.dart';

void main() {
  group('Base64Url', () {
    test('decodes unpadded Base64url challenge bytes', () {
      // "hello" in Base64url is aGVsbG8 (unpadded).
      final decoded = Base64Url.decode('aGVsbG8');
      expect(String.fromCharCodes(decoded), 'hello');
    });

    test('normalises padded input', () {
      expect(Base64Url.decode('aGVsbG8='), Base64Url.decode('aGVsbG8'));
    });

    test('encodes without padding', () {
      final encoded = Base64Url.encode([104, 101, 108, 108, 111]);
      expect(encoded, 'aGVsbG8');
      expect(encoded.contains('='), isFalse);
    });

    test('rejects empty values', () {
      expect(Base64Url.isValid(''), isFalse);
      expect(Base64Url.isValid('   '), isFalse);
    });

    test('round-trips arbitrary bytes', () {
      final bytes = List<int>.generate(64, (index) => index * 3 % 256);
      expect(Base64Url.decode(Base64Url.encode(bytes)), bytes);
    });
  });
}
