import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/entity/model/connection.dart';
import 'package:gf_app/entity/model/platform.dart';
import 'package:gf_app/back/repository/auth.dart';
import 'package:gf_app/back/share/error.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _discovery = {
  'issuer': 'https://id.example.test/realms/gorape',
  'authorization_endpoint':
      'https://id.example.test/realms/gorape/protocol/openid-connect/auth',
  'token_endpoint':
      'https://id.example.test/realms/gorape/protocol/openid-connect/token',
  'end_session_endpoint':
      'https://id.example.test/realms/gorape/protocol/openid-connect/logout',
  'jwks_uri':
      'https://id.example.test/realms/gorape/protocol/openid-connect/certs',
  'response_types_supported': ['code'],
  'subject_types_supported': ['public'],
  'id_token_signing_alg_values_supported': ['RS256'],
};

void main() {
  group('BrowserAuthRepository', () {
    test(
      'auth repository factory uses browser PKCE on all desktop and web targets',
      () {
        const settings = ConnectionSettings(
          apiBaseUrl: 'https://api.example.test',
          issuer: 'https://id.example.test/realms/gorape',
          clientId: 'gorape-client',
          redirectUri: 'http://127.0.0.1:8401/oauth2redirect',
        );
        for (final platform in const [
          RuntimePlatform.windows,
          RuntimePlatform.linux,
          RuntimePlatform.web,
        ]) {
          expect(
            newAuthRepository(settings, platform),
            isA<BrowserAuthRepository>(),
          );
        }
      },
    );

    test('supports Windows, Linux, and Web browser PKCE adapters', () {
      for (final platform in const [
        RuntimePlatform.windows,
        RuntimePlatform.linux,
        RuntimePlatform.web,
      ]) {
        final repository = BrowserAuthRepository(
          settings: const ConnectionSettings(
            apiBaseUrl: 'https://api.example.test',
            issuer: 'https://id.example.test/realms/gorape',
            clientId: 'gorape-client',
            redirectUri: 'http://127.0.0.1:8401/oauth2redirect',
          ),
          platform: platform,
          httpClient: MockClient((_) async => http.Response('{}', 200)),
          browserAuthFlow:
              ({
                required authorizationUrl,
                required redirectUri,
                required platform,
              }) async => '',
        );
        expect(repository.isSupported, isTrue);
      }
    });

    test(
      'registers a Keycloak passkey through the passwordless AIA action',
      () async {
        late Uri capturedAuthorizationUrl;
        final repository = BrowserAuthRepository(
          settings: const ConnectionSettings(
            apiBaseUrl: 'https://api.example.test',
            issuer: 'https://id.example.test/realms/gorape',
            clientId: 'gorape-client',
            redirectUri: 'http://127.0.0.1:8401/oauth2redirect',
          ),
          platform: RuntimePlatform.linux,
          httpClient: MockClient((request) async {
            if (request.url.path.endsWith(
              '/.well-known/openid-configuration',
            )) {
              return http.Response(jsonEncode(_discovery), 200);
            }
            fail('unexpected HTTP request ${request.url}');
          }),
          browserAuthFlow:
              ({
                required authorizationUrl,
                required redirectUri,
                required platform,
              }) async {
                capturedAuthorizationUrl = authorizationUrl;
                return redirectUri
                    .replace(
                      queryParameters: {
                        'state': authorizationUrl.queryParameters['state'],
                        'error': 'access_denied',
                      },
                    )
                    .toString();
              },
        );

        await expectLater(
          repository.registerPasskey(),
          throwsA(isA<AuthException>()),
        );
        expect(
          capturedAuthorizationUrl.queryParameters['kc_action'],
          'webauthn-register-passwordless',
        );
        expect(
          capturedAuthorizationUrl.queryParameters['code_challenge_method'],
          'S256',
        );
      },
    );

    test('uses state and PKCE and requests prompt=login when asked', () async {
      late Uri capturedAuthorizationUrl;
      late Uri callbackUri;
      final repository = BrowserAuthRepository(
        settings: const ConnectionSettings(
          apiBaseUrl: 'https://api.example.test',
          issuer: 'https://id.example.test/realms/gorape',
          clientId: 'gorape-client',
          redirectUri: 'http://127.0.0.1:8401/oauth2redirect',
        ),
        platform: RuntimePlatform.linux,
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/.well-known/openid-configuration')) {
            return http.Response(jsonEncode(_discovery), 200);
          }
          fail('unexpected HTTP request ${request.url}');
        }),
        browserAuthFlow:
            ({
              required authorizationUrl,
              required redirectUri,
              required platform,
            }) async {
              capturedAuthorizationUrl = authorizationUrl;
              callbackUri = redirectUri.replace(
                queryParameters: {
                  'state': authorizationUrl.queryParameters['state'],
                  'error': 'access_denied',
                },
              );
              return callbackUri.toString();
            },
      );

      await expectLater(
        repository.signIn(forceLogin: true, requirePasskey: true),
        throwsA(isA<AuthException>()),
      );
      expect(callbackUri.toString(), startsWith('http://127.0.0.1:8401/'));
      expect(capturedAuthorizationUrl.queryParameters['response_type'], 'code');
      expect(
        capturedAuthorizationUrl.queryParameters['code_challenge_method'],
        'S256',
      );
      expect(
        capturedAuthorizationUrl.queryParameters['acr_values'],
        'gorape-passkey',
      );
      expect(
        capturedAuthorizationUrl.queryParameters['code_challenge'],
        isNotEmpty,
      );
      expect(capturedAuthorizationUrl.queryParameters['state'], isNotEmpty);
      expect(capturedAuthorizationUrl.queryParameters['prompt'], 'login');
      expect(
        capturedAuthorizationUrl.queryParameters['redirect_uri'],
        'http://127.0.0.1:8401/oauth2redirect',
      );
    });

    test(
      'rejects callbacks that do not match the registered loopback URI',
      () async {
        final repository = BrowserAuthRepository(
          settings: const ConnectionSettings(
            apiBaseUrl: 'https://api.example.test',
            issuer: 'https://id.example.test/realms/gorape',
            clientId: 'gorape-client',
            redirectUri: 'http://127.0.0.1:8401/oauth2redirect',
          ),
          platform: RuntimePlatform.windows,
          httpClient: MockClient((request) async {
            if (request.url.path.endsWith(
              '/.well-known/openid-configuration',
            )) {
              return http.Response(jsonEncode(_discovery), 200);
            }
            fail('unexpected HTTP request ${request.url}');
          }),
          browserAuthFlow:
              ({
                required authorizationUrl,
                required redirectUri,
                required platform,
              }) async =>
                  'http://127.0.0.1:8402/oauth2redirect?state=${authorizationUrl.queryParameters['state']}&error=access_denied',
        );

        await expectLater(
          repository.signIn(),
          throwsA(
            isA<AuthException>().having(
              (error) => error.code,
              'code',
              'redirect_mismatch',
            ),
          ),
        );
      },
    );
  });
}
