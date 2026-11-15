import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:openid_client/openid_client.dart' as oidc;

import '../../entity/model/auth_tokens.dart';
import '../../entity/model/connection.dart';
import '../../entity/model/platform.dart';
import '../share/error.dart';
import '../share/http_client.dart';

/// Platform OIDC adapter.
abstract interface class AuthRepository {
  /// GF-00411 — Computes AuthRepository.isSupported.
  bool get isSupported;

  /// GF-00412 — Computes AuthRepository.unsupportedReason.
  String? get unsupportedReason;

  /// GF-00413 — Handles sign in in AuthRepository.
  Future<AuthTokens> signIn({
    bool forceLogin = false,
    bool requirePasskey = false,
  });

  /// Starts Keycloak's WebAuthn Register Passwordless required action using
  /// OIDC Application-Initiated Actions. `true` means Keycloak reported success.
  Future<bool> registerPasskey();

  /// GF-00414 — Handles refresh in AuthRepository.
  Future<AuthTokens> refresh(AuthTokens tokens);

  /// GF-00415 — Handles sign out in AuthRepository.
  Future<void> signOut(AuthTokens tokens);
}

final class UnsupportedAuthRepository implements AuthRepository {
  /// GF-00416 — Initializes UnsupportedAuthRepository.
  const UnsupportedAuthRepository(this.unsupportedReason);

  @override
  final String? unsupportedReason;

  /// GF-00417 — Computes UnsupportedAuthRepository.isSupported.
  @override
  bool get isSupported => false;

  /// GF-00418 — Handles sign in in UnsupportedAuthRepository.
  @override
  Future<AuthTokens> signIn({
    bool forceLogin = false,
    bool requirePasskey = false,
  }) {
    throw StateError('OIDC is not supported on this platform');
  }

  @override
  Future<bool> registerPasskey() =>
      throw StateError('OIDC is not supported on this platform');

  /// GF-00419 — Handles refresh in UnsupportedAuthRepository.
  @override
  Future<AuthTokens> refresh(AuthTokens tokens) {
    throw StateError('OIDC is not supported on this platform');
  }

  /// GF-00420 — Handles sign out in UnsupportedAuthRepository.
  @override
  Future<void> signOut(AuthTokens tokens) async {}
}

final class AppAuthRepository implements AuthRepository {
  /// GF-00421 — Initializes AppAuthRepository.
  AppAuthRepository({
    required ConnectionSettings settings,
    FlutterAppAuth? appAuth,
    http.Client? httpClient,
    this.discoveryTimeout = const Duration(seconds: 10),
  }) : _settings = settings,
       _appAuth = appAuth ?? const FlutterAppAuth(),
       _http = httpClient ?? newDefaultHttpClient();

  final ConnectionSettings _settings;
  final FlutterAppAuth _appAuth;
  final http.Client _http;
  final Duration discoveryTimeout;

  /// GF-00422 — Computes AppAuthRepository._allowInsecure.
  bool get _allowInsecure => _settings.usesInsecureTransport;

  /// GF-00423 — Computes AppAuthRepository._issuerUsesHttp.
  bool get _issuerUsesHttp => Uri.tryParse(_settings.issuer)?.scheme == 'http';

  /// GF-00424 — Computes AppAuthRepository.isSupported.
  @override
  bool get isSupported => true;

  /// GF-00425 — Computes AppAuthRepository.unsupportedReason.
  @override
  String? get unsupportedReason => null;

  /// GF-00426 — Handles sign in in AppAuthRepository.
  @override
  Future<AuthTokens> signIn({
    bool forceLogin = false,
    bool requirePasskey = false,
  }) async {
    try {
      final response = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _settings.clientId,
          _settings.redirectUri,
          issuer: _settings.issuer,
          scopes: _settings.scopes,
          promptValues: forceLogin || requirePasskey ? const ['login'] : null,
          additionalParameters: {
            if (requirePasskey) 'acr_values': 'gorape-passkey',
          },
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
  Future<bool> registerPasskey() async {
    try {
      final response = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _settings.clientId,
          _settings.redirectUri,
          issuer: _settings.issuer,
          scopes: _settings.scopes,
          additionalParameters: const {
            'kc_action': 'webauthn-register-passwordless:skip_if_exists',
          },
          allowInsecureConnections: _allowInsecure,
        ),
      );
      final status =
          response.authorizationAdditionalParameters?['kc_action_status'];
      if (status == 'success') return true;
      if (status == 'cancelled') return false;
      throw const AuthException(
        'MCODE-00511',
        code: 'passkey_registration_status_missing',
        guidance: 'MCODE-00512',
      );
    } on FlutterAppAuthUserCancelledException {
      return false;
    } on FlutterAppAuthPlatformException catch (error) {
      throw _platformError(error);
    } on PlatformException catch (error) {
      throw AuthException(
        'MCODE-00515',
        code: error.code,
        guidance: error.message,
      );
    }
  }

  /// GF-00427 — Handles refresh in AppAuthRepository.
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

  /// GF-00428 — Handles sign out in AppAuthRepository.
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

  /// GF-00429 — Handles fetch service configuration in AppAuthRepository.
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

  /// GF-00430 — Handles tokens from in AppAuthRepository.
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

  /// GF-00431 — Handles platform error in AppAuthRepository.
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

/// GF-00432 — Creates an instance for new auth repository.
AuthRepository newAuthRepository(
  ConnectionSettings settings,
  RuntimePlatform platform, {
  http.Client? httpClient,
  BrowserAuthFlow? browserAuthFlow,
}) => switch (platform) {
  RuntimePlatform.android ||
  RuntimePlatform.ios ||
  RuntimePlatform.macos => AppAuthRepository(
    settings: settings,
    httpClient: httpClient,
  ),
  RuntimePlatform.windows ||
  RuntimePlatform.linux ||
  RuntimePlatform.web => BrowserAuthRepository(
    settings: settings,
    platform: platform,
    httpClient: httpClient,
    browserAuthFlow: browserAuthFlow,
  ),
  RuntimePlatform.unknown => const UnsupportedAuthRepository(
    'プラットフォームを判定できないためOIDCを開始できません。',
  ),
};

typedef BrowserAuthFlow =
    Future<String> Function({
      required Uri authorizationUrl,
      required Uri redirectUri,
      required RuntimePlatform platform,
    });

/// OIDC Authorization Code + PKCE for Web and desktop platforms without
/// flutter_appauth implementations. Desktop uses the system browser and a
/// loopback callback; Web uses the same-origin auth.html callback page.
final class BrowserAuthRepository implements AuthRepository {
  BrowserAuthRepository({
    required ConnectionSettings settings,
    required this.platform,
    http.Client? httpClient,
    BrowserAuthFlow? browserAuthFlow,
    this.discoveryTimeout = const Duration(seconds: 10),
  }) : _settings = settings,
       _http = httpClient ?? newDefaultHttpClient() {
    _browserAuthFlow = browserAuthFlow ?? _authenticateInBrowser;
  }

  final ConnectionSettings _settings;
  final RuntimePlatform platform;
  final http.Client _http;
  late final BrowserAuthFlow _browserAuthFlow;
  final Duration discoveryTimeout;

  bool get _allowInsecure => _settings.usesInsecureTransport;

  @override
  bool get isSupported =>
      platform == RuntimePlatform.windows ||
      platform == RuntimePlatform.linux ||
      platform == RuntimePlatform.web;

  @override
  String? get unsupportedReason => null;

  @override
  Future<AuthTokens> signIn({
    bool forceLogin = false,
    bool requirePasskey = false,
  }) async {
    try {
      final redirect = _checkedRedirectUri();
      final client = await _client();
      final nonce = _randomBase64Url(32);
      final flow = oidc.Flow.authorizationCodeWithPKCE(
        client,
        scopes: _settings.scopes,
        prompt: forceLogin || requirePasskey ? 'login' : null,
        additionalParameters: {
          'nonce': nonce,
          if (requirePasskey) 'acr_values': 'gorape-passkey',
        },
      );
      flow.redirectUri = redirect;
      final callback = await _browserAuthFlow(
        authorizationUrl: flow.authenticationUri,
        redirectUri: redirect,
        platform: platform,
      );
      final callbackUri = Uri.parse(callback);
      _validateCallback(callbackUri, redirect);
      final credential = await flow.callback(
        callbackUri.queryParameters.cast<String, String>(),
      );
      final violations = await credential.validateToken().toList();
      if (violations.isNotEmpty) {
        throw AuthException(
          'KeycloakのID tokenを検証できませんでした。',
          code: 'invalid_id_token',
          guidance: violations.map((error) => error.toString()).join('\n'),
        );
      }
      if (credential.idToken.claims.nonce != nonce) {
        throw const AuthException(
          'KeycloakのID token nonceが一致しません。',
          code: 'oidc_nonce_mismatch',
        );
      }
      return _tokensFromCredential(credential);
    } on FormatException catch (error) {
      throw AuthException(
        'KeycloakのOIDC応答を検証できませんでした。',
        code: 'invalid_oidc_response',
        guidance: error.message,
      );
    } on PlatformException catch (error) {
      if (_isCancellation(error)) throw const AuthCancelledException();
      throw AuthException(
        'Keycloakログインに失敗しました。',
        code: error.code,
        guidance: error.message,
      );
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw AuthException(
        'Keycloakログインに失敗しました。',
        code: 'oidc_browser_error',
        guidance: error.toString(),
      );
    }
  }

  @override
  Future<bool> registerPasskey() async {
    try {
      final redirect = _checkedRedirectUri();
      final client = await _client();
      final nonce = _randomBase64Url(32);
      final flow = oidc.Flow.authorizationCodeWithPKCE(
        client,
        scopes: _settings.scopes,
        additionalParameters: {
          'nonce': nonce,
          'kc_action': 'webauthn-register-passwordless:skip_if_exists',
        },
      )..redirectUri = redirect;
      final callback = await _browserAuthFlow(
        authorizationUrl: flow.authenticationUri,
        redirectUri: redirect,
        platform: platform,
      );
      final callbackUri = Uri.parse(callback);
      _validateCallback(callbackUri, redirect);
      final credential = await flow.callback(
        callbackUri.queryParameters.cast<String, String>(),
      );
      final violations = await credential.validateToken().toList();
      if (violations.isNotEmpty || credential.idToken.claims.nonce != nonce) {
        throw const AuthException(
          'MCODE-00513',
          code: 'passkey_registration_oidc_invalid',
        );
      }
      final status = callbackUri.queryParameters['kc_action_status'];
      if (status == 'success') return true;
      if (status == 'cancelled') return false;
      throw const AuthException(
        'MCODE-00511',
        code: 'passkey_registration_status_missing',
        guidance: 'MCODE-00512',
      );
    } on FormatException catch (error) {
      throw AuthException(
        'MCODE-00514',
        code: 'passkey_registration_invalid',
        guidance: error.message,
      );
    } on PlatformException catch (error) {
      if (_isCancellation(error)) return false;
      throw AuthException(
        'MCODE-00515',
        code: error.code,
        guidance: error.message,
      );
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw AuthException(
        'MCODE-00515',
        code: 'passkey_registration_failed',
        guidance: error.toString(),
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
      final client = await _client();
      final credential = client.createCredential(
        accessToken: tokens.accessToken,
        refreshToken: refreshToken,
        idToken: tokens.idToken,
        expiresAt: tokens.expiresAt,
      );
      final refreshed = await credential.getTokenResponse(true);
      final response = credential.response ?? const <String, dynamic>{};
      final newIDToken = response['id_token'] as String?;
      if (newIDToken != null && newIDToken.isNotEmpty) {
        final validationCredential = client.createCredential(
          accessToken: refreshed.accessToken,
          idToken: newIDToken,
        );
        final violations = await validationCredential.validateToken().toList();
        if (violations.isNotEmpty) {
          throw AuthException(
            'Keycloakの更新済みID tokenを検証できませんでした。',
            code: 'invalid_id_token',
            guidance: violations.map((error) => error.toString()).join('\n'),
          );
        }
      }
      final accessToken = refreshed.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        throw const AuthException(
          'Keycloakからアクセストークンが返されませんでした。',
          code: 'missing_access_token',
        );
      }
      return AuthTokens(
        accessToken: accessToken,
        idToken: newIDToken ?? tokens.idToken,
        refreshToken: refreshed.refreshToken ?? refreshToken,
        expiresAt: refreshed.expiresAt,
        scopes: _scopesFrom(response['scope']) ?? tokens.scopes,
      );
    } on FormatException catch (error) {
      throw AuthException(
        'Keycloakのtoken応答を解析できませんでした。',
        code: 'invalid_token_response',
        guidance: error.message,
      );
    } on AuthException {
      rethrow;
    } on http.ClientException catch (error) {
      throw NetworkException(
        'Keycloakへ接続できませんでした。',
        code: 'oidc_network_error',
        guidance: error.message,
      );
    } on Object catch (error) {
      throw AuthException(
        'セッションの更新に失敗しました。もう一度ログインしてください。',
        code: 'oidc_refresh_failed',
        guidance: error.toString(),
      );
    }
  }

  @override
  Future<void> signOut(AuthTokens tokens) async {
    if (tokens.idToken == null || tokens.idToken!.isEmpty) return;
    try {
      final client = await _client();
      final redirect = _checkedRedirectUri();
      final state = _randomBase64Url(24);
      final url = client
          .createCredential(idToken: tokens.idToken)
          .generateLogoutUrl(redirectUri: redirect, state: state);
      if (url == null) return;
      final callback = await _browserAuthFlow(
        authorizationUrl: url,
        redirectUri: redirect,
        platform: platform,
      );
      final callbackUri = Uri.parse(callback);
      _validateCallback(callbackUri, redirect);
      if (callbackUri.queryParameters['state'] != state) return;
    } on Object {
      // Local sign-out still succeeds when the browser or IdP is unavailable.
    }
  }

  Future<oidc.Issuer> _discover() async {
    final issuer = _trimTrailingSlash(_settings.issuer);
    final uri = Uri.parse('$issuer/.well-known/openid-configuration');
    late http.Response response;
    try {
      response = await _http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(discoveryTimeout);
    } on TimeoutException {
      throw const NetworkException(
        'Keycloak discoveryがタイムアウトしました。',
        code: 'oidc_discovery_timeout',
      );
    } on http.ClientException catch (error) {
      throw NetworkException(
        'Keycloakへ接続できませんでした。',
        code: 'oidc_network_error',
        guidance: error.message,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Keycloak discoveryがHTTP ${response.statusCode}を返しました。',
        statusCode: response.statusCode,
        code: 'oidc_discovery_failed',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid OIDC discovery document.');
    }
    final discoveredIssuer = decoded['issuer'];
    if (discoveredIssuer is! String || discoveredIssuer != _settings.issuer) {
      throw const AuthException(
        'OIDC discovery issuerが設定と一致しません。',
        code: 'issuer_mismatch',
      );
    }
    final metadata = oidc.OpenIdProviderMetadata.fromJson(decoded);
    final discoveredAuthorization = metadata.authorizationEndpoint;
    final discoveredToken = metadata.tokenEndpoint;
    if (discoveredToken == null) {
      throw const AuthException(
        'OIDC discoveryにtoken endpointがありません。',
        code: 'missing_token_endpoint',
      );
    }
    _validateEndpoint(discoveredAuthorization, 'authorization_endpoint');
    _validateEndpoint(discoveredToken, 'token_endpoint');
    final endSession = metadata.endSessionEndpoint;
    if (endSession != null) {
      _validateEndpoint(endSession, 'end_session_endpoint');
    }
    return oidc.Issuer(metadata);
  }

  void _validateEndpoint(Uri uri, String name) {
    final issuerIsHttp = Uri.tryParse(_settings.issuer)?.scheme == 'http';
    if (uri.scheme != 'https' &&
        !(issuerIsHttp && _allowInsecure && uri.scheme == 'http')) {
      throw AuthException(
        '$name must use HTTPS outside local development.',
        code: 'insecure_oidc_endpoint',
      );
    }
    if (!uri.hasScheme || uri.host.isEmpty) {
      throw AuthException('Invalid OIDC $name.', code: 'invalid_oidc_endpoint');
    }
  }

  Future<oidc.Client> _client() async {
    final issuer = await _discover();
    return oidc.Client(issuer, _settings.clientId, httpClient: _http);
  }

  Uri _checkedRedirectUri() {
    final redirect = Uri.tryParse(_settings.redirectUri);
    if (redirect == null || !redirect.hasScheme || redirect.host.isEmpty) {
      throw const ConfigurationException(
        'OIDC redirect URIが有効ではありません。',
        code: 'invalid_redirect_uri',
      );
    }
    if (platform == RuntimePlatform.web) {
      final base = Uri.base;
      if (redirect.origin != base.origin ||
          !redirect.path.endsWith('/auth.html')) {
        throw const ConfigurationException(
          'Web redirect URIはアプリと同じoriginのauth.htmlにしてください。',
          code: 'invalid_web_redirect_uri',
        );
      }
      if (redirect.scheme != 'https' &&
          !(redirect.scheme == 'http' &&
              (redirect.host == 'localhost' || redirect.host == '127.0.0.1'))) {
        throw const ConfigurationException(
          'Web OIDC callback must use HTTPS except on localhost.',
          code: 'insecure_web_redirect_uri',
        );
      }
    } else {
      if (redirect.scheme != 'http' ||
          (redirect.host != 'localhost' && redirect.host != '127.0.0.1') ||
          !redirect.hasPort ||
          redirect.path.isEmpty) {
        throw const ConfigurationException(
          'Windows/Linux redirect URIはhttp://127.0.0.1:{port}/callback形式にしてください。',
          code: 'invalid_loopback_redirect_uri',
        );
      }
    }
    return redirect;
  }

  Future<String> _authenticateInBrowser({
    required Uri authorizationUrl,
    required Uri redirectUri,
    required RuntimePlatform platform,
  }) {
    final callback =
        platform == RuntimePlatform.windows || platform == RuntimePlatform.linux
        ? redirectUri.toString()
        : redirectUri.scheme;
    return FlutterWebAuth2.authenticate(
      url: authorizationUrl.toString(),
      callbackUrlScheme: callback,
      options: FlutterWebAuth2Options(
        useWebview: false,
        timeout: 300,
        httpsHost: redirectUri.host,
        httpsPath: redirectUri.path,
      ),
    );
  }

  AuthTokens _tokensFromCredential(oidc.Credential credential) {
    final response = credential.response ?? const <String, dynamic>{};
    final accessToken = response['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const AuthException(
        'Keycloakからアクセストークンが返されませんでした。',
        code: 'missing_access_token',
      );
    }
    return AuthTokens(
      accessToken: accessToken,
      idToken: response['id_token'] as String?,
      refreshToken: response['refresh_token'] as String?,
      expiresAt: _expiresAtFrom(response['expires_at']),
      scopes: _scopesFrom(response['scope']) ?? _settings.scopes,
    );
  }

  static DateTime? _expiresAtFrom(Object? value) {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    if (value is String) {
      final asInt = int.tryParse(value);
      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
      }
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<String>? _scopesFrom(Object? value) {
    if (value is String) {
      return value
          .split(RegExp(r'\s+'))
          .where((scope) => scope.isNotEmpty)
          .toList();
    }
    if (value is List) return value.whereType<String>().toList(growable: false);
    return null;
  }

  static void _validateCallback(Uri callback, Uri redirect) {
    if (callback.scheme != redirect.scheme ||
        callback.host != redirect.host ||
        callback.port != redirect.port ||
        callback.path != redirect.path) {
      throw const AuthException(
        'OIDC redirect URIが登録済みcallbackと一致しません。',
        code: 'redirect_mismatch',
      );
    }
  }

  static bool _isCancellation(PlatformException error) =>
      error.code.toLowerCase().contains('cancel');

  static String _randomBase64Url(int bytes) {
    final random = Random.secure();
    final value = List<int>.generate(bytes, (_) => random.nextInt(256));
    return base64Url.encode(value).replaceAll('=', '');
  }

  static String _trimTrailingSlash(String value) {
    var result = value.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
