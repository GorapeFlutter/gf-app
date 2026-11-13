import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/auth/auth_tokens.dart';
import 'package:gf_app/core/config/connection_settings.dart';
import 'package:gf_app/core/config/runtime_platform.dart';

void main() {
  group('ConnectionSettings', () {
    test('uses emulator API host on Android and localhost elsewhere', () {
      final android = ConnectionSettings.defaultsFor(RuntimePlatform.android);
      final macos = ConnectionSettings.defaultsFor(RuntimePlatform.macos);

      expect(android.apiBaseUrl, 'http://10.0.2.2:8000');
      expect(macos.apiBaseUrl, 'http://localhost:8000');
      expect(android.issuer, 'http://localhost:8080/realms/gorape');
      expect(android.clientId, 'gorape-client');
      expect(android.redirectUri, ConnectionSettings.flutterRedirectUri);
      expect(android.scopes, ['openid', 'profile']);
    });

    test('validates required fields', () {
      const settings = ConnectionSettings(
        apiBaseUrl: 'not a url',
        issuer: '',
        clientId: '',
        redirectUri: '',
        scopes: ['profile'],
      );
      final errors = settings.validate();

      expect(errors, hasLength(5));
      expect(errors.join('\n'), contains('openid'));
    });

    test('round-trips through JSON', () {
      final settings = ConnectionSettings.defaultsFor(
        RuntimePlatform.android,
      ).copyWith(apiBaseUrl: 'https://gorape.example.com/');
      final decoded = ConnectionSettings.decode(settings.encode());

      expect(decoded, settings);
      expect(decoded.apiBaseUrl, 'https://gorape.example.com');
      expect(decoded.usesInsecureTransport, isTrue);
    });
  });

  group('AuthTokens', () {
    test('detects expiry with a safety skew', () {
      final tokens = AuthTokens(
        accessToken: 'token',
        expiresAt: DateTime.now().add(const Duration(seconds: 10)),
      );
      expect(tokens.isExpired(), isTrue);

      final valid = AuthTokens(
        accessToken: 'token',
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      expect(valid.isExpired(), isFalse);
    });

    test('round-trips token payloads and requires an access token', () {
      final tokens = AuthTokens(
        accessToken: 'access',
        idToken: 'id',
        refreshToken: 'refresh',
        expiresAt: DateTime.utc(2030, 1, 2, 3, 4, 5),
        scopes: const ['openid', 'profile'],
      );
      final decoded = AuthTokens.decode(tokens.encode());

      expect(decoded.accessToken, 'access');
      expect(decoded.idToken, 'id');
      expect(decoded.refreshToken, 'refresh');
      expect(decoded.expiresAt, DateTime.utc(2030, 1, 2, 3, 4, 5));
      expect(decoded.scopes, ['openid', 'profile']);
      expect(decoded.canRefresh, isTrue);

      expect(
        () => AuthTokens.decode('{"refresh_token":"only"}'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
