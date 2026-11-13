import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/entity/model/auth_tokens.dart';
import 'package:gf_app/entity/model/connection.dart';
import 'package:gf_app/repository/auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _tokens = AuthTokens(
  accessToken: 'access-token',
  idToken: 'id-token',
  refreshToken: 'refresh-token',
);

const _redirectUri = 'com.gorapeflutter.gfapp:/oauth2redirect';

ConnectionSettings _settings({
  String apiBaseUrl = 'http://localhost:8000',
  String issuer = 'http://localhost:8080/realms/gorape',
}) => ConnectionSettings(
  apiBaseUrl: apiBaseUrl,
  issuer: issuer,
  clientId: 'gorape-client',
  redirectUri: _redirectUri,
);

const _discovery = {
  'issuer': 'http://localhost:8080/realms/gorape',
  'authorization_endpoint':
      'http://localhost:8080/realms/gorape/protocol/openid-connect/auth',
  'token_endpoint':
      'http://localhost:8080/realms/gorape/protocol/openid-connect/token',
  'end_session_endpoint':
      'http://localhost:8080/realms/gorape/protocol/openid-connect/logout',
};

final class _RecordingAppAuth extends FlutterAppAuth {
  _RecordingAppAuth();

  EndSessionRequest? lastRequest;
  AuthorizationTokenRequest? lastAuthorizationRequest;
  int calls = 0;
  int authorizationCalls = 0;

  @override
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
    AuthorizationTokenRequest request,
  ) async {
    authorizationCalls++;
    lastAuthorizationRequest = request;
    return AuthorizationTokenResponse(
      'access-token',
      'refresh-token',
      null,
      'id-token',
      'Bearer',
      const ['openid'],
      null,
      null,
    );
  }

  @override
  Future<EndSessionResponse> endSession(EndSessionRequest request) async {
    calls++;
    lastRequest = request;
    return EndSessionResponse(null);
  }
}

void main() {
  group('AppAuthRepository.signIn', () {
    test('forces Keycloak to show the login form for admin sign-in', () async {
      final appAuth = _RecordingAppAuth();
      final repository = AppAuthRepository(
        settings: _settings(),
        appAuth: appAuth,
      );

      await repository.signIn(forceLogin: true);

      expect(appAuth.authorizationCalls, 1);
      expect(appAuth.lastAuthorizationRequest?.promptValues, ['login']);
    });
  });

  group('AppAuthRepository.signOut', () {
    test('uses discovery so HTTP issuers avoid the native crash', () async {
      final appAuth = _RecordingAppAuth();
      final requested = <Uri>[];
      final repository = AppAuthRepository(
        settings: _settings(),
        appAuth: appAuth,
        httpClient: MockClient((request) async {
          requested.add(request.url);
          return http.Response(jsonEncode(_discovery), 200);
        }),
      );

      await repository.signOut(_tokens);

      expect(requested, [
        Uri.parse(
          'http://localhost:8080/realms/gorape/.well-known/openid-configuration',
        ),
      ]);
      expect(appAuth.calls, 1);
      final request = appAuth.lastRequest!;
      expect(request.idTokenHint, 'id-token');
      expect(request.postLogoutRedirectUrl, _redirectUri);
      expect(request.allowInsecureConnections, isTrue);
      expect(request.issuer, isNull);
      expect(
        request.serviceConfiguration?.authorizationEndpoint,
        _discovery['authorization_endpoint'],
      );
      expect(
        request.serviceConfiguration?.tokenEndpoint,
        _discovery['token_endpoint'],
      );
      expect(
        request.serviceConfiguration?.endSessionEndpoint,
        _discovery['end_session_endpoint'],
      );
    });

    test('skips Keycloak logout when HTTP discovery fails', () async {
      final appAuth = _RecordingAppAuth();
      final repository = AppAuthRepository(
        settings: _settings(),
        appAuth: appAuth,
        httpClient: MockClient((_) async => http.Response('unavailable', 503)),
      );

      await repository.signOut(_tokens);

      expect(appAuth.calls, 0);
    });

    test('falls back to issuer discovery for HTTPS issuers', () async {
      final appAuth = _RecordingAppAuth();
      final repository = AppAuthRepository(
        settings: _settings(
          apiBaseUrl: 'https://gorape.example.com',
          issuer: 'https://keycloak.example.com/realms/gorape',
        ),
        appAuth: appAuth,
        httpClient: MockClient((_) async => http.Response('unavailable', 503)),
      );

      await repository.signOut(_tokens);

      expect(appAuth.calls, 1);
      final request = appAuth.lastRequest!;
      expect(request.serviceConfiguration, isNull);
      expect(request.issuer, 'https://keycloak.example.com/realms/gorape');
      expect(request.allowInsecureConnections, isFalse);
    });

    test('does not contact discovery without an ID token', () async {
      final appAuth = _RecordingAppAuth();
      var discoveryCalls = 0;
      final repository = AppAuthRepository(
        settings: _settings(),
        appAuth: appAuth,
        httpClient: MockClient((_) async {
          discoveryCalls++;
          return http.Response(jsonEncode(_discovery), 200);
        }),
      );

      await repository.signOut(const AuthTokens(accessToken: 'access-token'));

      expect(discoveryCalls, 0);
      expect(appAuth.calls, 0);
    });
  });
}
