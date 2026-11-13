import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

import '../core/config/connection_settings.dart';
import '../core/errors/app_exception.dart';
import 'auth_tokens.dart';
import 'oidc_service.dart';

/// Keycloak Authorization Code + PKCE adapter backed by AppAuth.
///
/// Supported by flutter_appauth on Android, iOS, and macOS. Windows and other
/// desktop targets are reported as unsupported rather than silently falling
/// back to an insecure flow.
class AppAuthOidcService implements OidcService {
  AppAuthOidcService({
    required ConnectionSettings settings,
    FlutterAppAuth? appAuth,
  }) : _settings = settings,
       _appAuth = appAuth ?? const FlutterAppAuth();

  final ConnectionSettings _settings;
  final FlutterAppAuth _appAuth;

  bool get _allowInsecure => _settings.usesInsecureTransport;

  @override
  bool get isSupported => true;

  @override
  String? get unsupportedReason => null;

  @override
  Future<AuthTokens> signIn() async {
    try {
      final response = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _settings.clientId,
          _settings.redirectUri,
          issuer: _settings.issuer,
          scopes: _settings.scopes,
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
      await _appAuth.endSession(
        EndSessionRequest(
          idTokenHint: idToken,
          postLogoutRedirectUrl: _settings.redirectUri,
          issuer: _settings.issuer,
          allowInsecureConnections: _allowInsecure,
        ),
      );
    } on Object {
      // Local sign-out must still succeed if Keycloak cannot be reached.
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
