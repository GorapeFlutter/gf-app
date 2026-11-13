import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;

import '../entity/model/auth_tokens.dart';
import '../entity/model/connection.dart';
import '../entity/model/platform.dart';
import '../share/error.dart';

/// Platform OIDC adapter.
abstract interface class AuthRepository {
  bool get isSupported;

  String? get unsupportedReason;

  Future<AuthTokens> signIn({bool forceLogin = false});

  Future<AuthTokens> refresh(AuthTokens tokens);

  Future<void> signOut(AuthTokens tokens);
}

final class UnsupportedAuthRepository implements AuthRepository {
  const UnsupportedAuthRepository(this.unsupportedReason);

  @override
  final String? unsupportedReason;

  @override
  bool get isSupported => false;

  @override
  Future<AuthTokens> signIn({bool forceLogin = false}) {
    throw StateError('OIDC is not supported on this platform');
  }

  @override
  Future<AuthTokens> refresh(AuthTokens tokens) {
    throw StateError('OIDC is not supported on this platform');
  }

  @override
  Future<void> signOut(AuthTokens tokens) async {}
}

final class AppAuthRepository implements AuthRepository {
  AppAuthRepository({
    required ConnectionSettings settings,
    FlutterAppAuth? appAuth,
    http.Client? httpClient,
    this.discoveryTimeout = const Duration(seconds: 10),
  }) : _settings = settings,
       _appAuth = appAuth ?? const FlutterAppAuth(),
       _http = httpClient ?? http.Client();

  final ConnectionSettings _settings;
  final FlutterAppAuth _appAuth;
  final http.Client _http;
  final Duration discoveryTimeout;

  bool get _allowInsecure => _settings.usesInsecureTransport;
  bool get _issuerUsesHttp => Uri.tryParse(_settings.issuer)?.scheme == 'http';

  @override
  bool get isSupported => true;

  @override
  String? get unsupportedReason => null;

  @override
  Future<AuthTokens> signIn({bool forceLogin = false}) async {
    try {
      final response = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _settings.clientId,
          _settings.redirectUri,
          issuer: _settings.issuer,
          scopes: _settings.scopes,
          promptValues: forceLogin ? const ['login'] : null,
          allowInsecureConnections: _allowInsecure,
        ),
      );
      return _tokensFrom(response);
    } on FlutterAppAuthUserCancelledException {
      throw const AuthCancelledException();
    } on FlutterAppAuthPlatformException catch (error) {
      throw _platformError(error);
    } on PlatformException catch (error) {
      throw AuthException(
        'Keycloakログインに失敗しました。',
        code: error.code,
        guidance: error.message,
      );
    }
  }

  @override
  Future<AuthTokens> refresh(AuthTokens tokens) async {
    final refreshToken = tokens.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const AuthException(
        'セッションを更新できません。もう一度ログインしてください。',
        code: 'missing_refresh_token',
      );
    }
    try {
      final response = await _appAuth.token(
        TokenRequest(
          _settings.clientId,
          _settings.redirectUri,
          issuer: _settings.issuer,
          scopes: _settings.scopes,
          refreshToken: refreshToken,
          allowInsecureConnections: _allowInsecure,
        ),
      );
      return _tokensFrom(response);
    } on FlutterAppAuthPlatformException catch (error) {
      throw _platformError(error);
    } on PlatformException catch (error) {
      throw AuthException(
        'セッションの更新に失敗しました。もう一度ログインしてください。',
        code: error.code,
        guidance: error.message,
      );
    }
  }

  @override
  Future<void> signOut(AuthTokens tokens) async {
    final idToken = tokens.idToken;
    if (idToken == null || idToken.isEmpty) return;
    try {
      // flutter_appauth 12.1.0 ignores allowInsecureConnections while fetching
      // the discovery document for endSession (the Android plugin shadows the
      // field with a local variable). Fetching the configuration here keeps
      // HTTP development issuers from crashing the Android process.
      final serviceConfiguration = await _fetchServiceConfiguration();
      if (serviceConfiguration == null && _issuerUsesHttp) {
        return;
      }
      await _appAuth.endSession(
        EndSessionRequest(
          idTokenHint: idToken,
          postLogoutRedirectUrl: _settings.redirectUri,
          issuer: serviceConfiguration == null ? _settings.issuer : null,
          serviceConfiguration: serviceConfiguration,
          allowInsecureConnections: _allowInsecure,
        ),
      );
    } on Object {
      // Local sign-out still succeeds if Keycloak cannot be reached.
    }
  }

  Future<AuthorizationServiceConfiguration?>
  _fetchServiceConfiguration() async {
    var issuer = _settings.issuer.trim();
    while (issuer.endsWith('/')) {
      issuer = issuer.substring(0, issuer.length - 1);
    }
    try {
      final response = await _http
          .get(Uri.parse('$issuer/.well-known/openid-configuration'))
          .timeout(discoveryTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final authorizationEndpoint = decoded['authorization_endpoint'];
      final tokenEndpoint = decoded['token_endpoint'];
      final endSessionEndpoint = decoded['end_session_endpoint'];
      if (authorizationEndpoint is! String ||
          tokenEndpoint is! String ||
          endSessionEndpoint is! String ||
          endSessionEndpoint.isEmpty) {
        return null;
      }
      return AuthorizationServiceConfiguration(
        authorizationEndpoint: authorizationEndpoint,
        tokenEndpoint: tokenEndpoint,
        endSessionEndpoint: endSessionEndpoint,
      );
    } on Object {
      return null;
    }
  }

  AuthTokens _tokensFrom(TokenResponse response) {
    final accessToken = response.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw const AuthException(
        'Keycloakからアクセストークンが返されませんでした。',
        code: 'missing_access_token',
      );
    }
    return AuthTokens(
      accessToken: accessToken,
      idToken: response.idToken,
      refreshToken: response.refreshToken,
      expiresAt: response.accessTokenExpirationDateTime,
      scopes: response.scopes ?? _settings.scopes,
    );
  }

  AuthException _platformError(FlutterAppAuthPlatformException error) {
    final details = error.platformErrorDetails;
    final code = details.error ?? details.code ?? error.code;
    final description = details.errorDescription;
    final guidance = StringBuffer();
    if (description != null && description.isNotEmpty) {
      guidance.write(description);
    }
    if (code == 'invalid_grant') {
      guidance.write('\nKeycloakのRedirect URI許可リストとアプリ設定が一致しているか確認してください。');
    }
    return AuthException(
      'Keycloakログインに失敗しました。',
      code: code,
      guidance: guidance.isEmpty ? null : guidance.toString(),
    );
  }
}

AuthRepository newAuthRepository(
  ConnectionSettings settings,
  RuntimePlatform platform, {
  http.Client? httpClient,
}) => switch (platform) {
  RuntimePlatform.android || RuntimePlatform.ios || RuntimePlatform.macos =>
    AppAuthRepository(settings: settings, httpClient: httpClient),
  RuntimePlatform.windows => const UnsupportedAuthRepository(
    'Windows向けflutter_appauth実装がありません。'
    'Authorization Code + PKCEをループバックリダイレクトで実装する必要があります。',
  ),
  RuntimePlatform.linux => const UnsupportedAuthRepository(
    'Linux向けflutter_appauth実装がありません。',
  ),
  RuntimePlatform.web => const UnsupportedAuthRepository(
    'このクライアントはWebを対象外としています。',
  ),
  RuntimePlatform.unknown => const UnsupportedAuthRepository(
    'プラットフォームを判定できないためOIDCを開始できません。',
  ),
};
