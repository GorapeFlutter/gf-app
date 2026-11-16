import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/back/repository/secure_store.dart';
import 'package:gf_app/back/usecase/connection.dart';
import 'package:gf_app/config/connection.dart';
import 'package:gf_app/entity/model/auth_tokens.dart';
import 'package:gf_app/entity/model/connection.dart';
import 'package:gf_app/entity/model/platform.dart';

void main() {
  group('ConnectionSettings', () {
    test(
      'uses the gorapeflutter.site HTTPS API and platform-specific OIDC redirects',
      () {
        final config = newConnectionConfig();
        final android = config.defaultsFor(RuntimePlatform.android);
        final macos = config.defaultsFor(RuntimePlatform.macos);
        final windows = config.defaultsFor(RuntimePlatform.windows);
        final linux = config.defaultsFor(RuntimePlatform.linux);
        final web = config.defaultsFor(RuntimePlatform.web);

        expect(android.apiBaseUrl, 'https://api.gorapeflutter.site:8443');
        expect(macos.apiBaseUrl, 'https://api.gorapeflutter.site:8443');
        expect(
          android.issuer,
          'https://idp.gorapeflutter.site:9443/realms/gorape',
        );
        expect(android.clientId, 'gorape-client');
        expect(android.redirectUri, ConnectionSettings.flutterRedirectUri);
        expect(windows.redirectUri, ConnectionSettings.desktopRedirectUri);
        expect(linux.redirectUri, ConnectionSettings.desktopRedirectUri);
        expect(web.redirectUri, 'https://app.gorapeflutter.site/auth.html');
        expect(android.scopes, ['openid', 'profile']);
      },
    );

    test(
      'migrates saved legacy API and HTTP issuer endpoints to current HTTPS endpoints',
      () async {
        final store = MemorySecureStore({
          ConnectionUsecaseImpl.storageKey: ConnectionSettings(
            apiBaseUrl: 'http://localhost:8000/',
            issuer: 'http://localhost:8080/realms/gorape',
            clientId: 'gorape-client',
            redirectUri: ConnectionSettings.flutterRedirectUri,
          ).encode(),
        });
        final usecase = newConnectionUsecase(store, newConnectionConfig());

        final settings = await usecase.load(RuntimePlatform.android);

        expect(settings.apiBaseUrl, 'https://api.gorapeflutter.site:8443');
        expect(
          ConnectionSettings.decode(
            store.values[ConnectionUsecaseImpl.storageKey]!,
          ).apiBaseUrl,
          'https://api.gorapeflutter.site:8443',
        );
        expect(
          settings.issuer,
          'https://idp.gorapeflutter.site:9443/realms/gorape',
        );
        expect(settings.usesInsecureTransport, isFalse);
        expect(
          ConnectionSettings.decode(
            store.values[ConnectionUsecaseImpl.storageKey]!,
          ).issuer,
          'https://idp.gorapeflutter.site:9443/realms/gorape',
        );
      },
    );

    test(
      'migrates the saved local Keycloak HTTP issuer to its HTTPS issuer',
      () async {
        final store = MemorySecureStore({
          ConnectionUsecaseImpl.storageKey: const ConnectionSettings(
            apiBaseUrl: 'https://api.gorapeflutter.site:8443',
            issuer: 'http://idp.gorapeflutter.site:8080/realms/gorape',
            clientId: 'gorape-client',
            redirectUri: ConnectionSettings.flutterRedirectUri,
          ).encode(),
        });
        final usecase = newConnectionUsecase(store, newConnectionConfig());

        final settings = await usecase.load(RuntimePlatform.android);

        expect(
          settings.issuer,
          'https://idp.gorapeflutter.site:9443/realms/gorape',
        );
        expect(
          ConnectionSettings.decode(
            store.values[ConnectionUsecaseImpl.storageKey]!,
          ).issuer,
          settings.issuer,
        );
      },
    );

    test('preserves custom domain endpoints without migrating them', () async {
      final store = MemorySecureStore({
        ConnectionUsecaseImpl.storageKey: const ConnectionSettings(
          apiBaseUrl: 'https://api.custom.example.com',
          issuer: 'https://idp.custom.example.com/realms/gorape',
          clientId: 'custom-client',
          redirectUri: ConnectionSettings.flutterRedirectUri,
        ).encode(),
      });
      final usecase = newConnectionUsecase(store, newConnectionConfig());

      final settings = await usecase.load(RuntimePlatform.android);

      expect(settings.apiBaseUrl, 'https://api.custom.example.com');
      expect(settings.issuer, 'https://idp.custom.example.com/realms/gorape');
      expect(settings.clientId, 'custom-client');
      expect(settings.usesInsecureTransport, isFalse);
      expect(
        settings.registrationUrl,
        'https://idp.custom.example.com/realms/gorape/protocol/openid-connect/registrations'
        '?client_id=custom-client'
        '&redirect_uri=com.gorapeflutter.gfapp%3A%2Foauth2redirect'
        '&response_type=code&scope=openid',
      );
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
      final settings = newConnectionConfig()
          .defaultsFor(RuntimePlatform.android)
          .copyWith(apiBaseUrl: 'https://gorape.example.com/');
      final decoded = ConnectionSettings.decode(settings.encode());

      expect(decoded, settings);
      expect(decoded.apiBaseUrl, 'https://gorape.example.com');
      expect(decoded.usesInsecureTransport, isFalse);
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
