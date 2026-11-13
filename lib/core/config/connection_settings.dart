import 'dart:convert';

import 'runtime_platform.dart';

/// Connection and OIDC settings used by the app.
///
/// These values mirror the development environment documented by the Gorape
/// repository. The OIDC issuer must be identical to the `iss` claim issued by
/// Keycloak; replacing only the host of an existing issuer will make token
/// validation fail.
class ConnectionSettings {
  const ConnectionSettings({
    required this.apiBaseUrl,
    required this.issuer,
    required this.clientId,
    required this.redirectUri,
    this.scopes = const ['openid', 'profile'],
  });

  static const String flutterRedirectUri =
      'com.gorapeflutter.gfapp:/oauth2redirect';

  final String apiBaseUrl;
  final String issuer;
  final String clientId;
  final String redirectUri;
  final List<String> scopes;

  static ConnectionSettings defaultsFor(RuntimePlatform platform) {
    return ConnectionSettings(
      // The Android emulator reaches the host through 10.0.2.2. The OIDC
      // issuer intentionally stays on localhost so it matches Keycloak's
      // `iss` claim; use `adb reverse tcp:8080 tcp:8080` for the browser flow.
      apiBaseUrl: platform == RuntimePlatform.android
          ? 'http://10.0.2.2:8000'
          : 'http://localhost:8000',
      issuer: 'http://localhost:8080/realms/gorape',
      clientId: 'gorape-client',
      redirectUri: flutterRedirectUri,
    );
  }

  /// Environment overrides are available for physical devices and CI.
  ///
  /// Example:
  /// `flutter run --dart-define=GORAPE_API_BASE_URL=http://192.168.1.10:8000`
  /// `--dart-define=GORAPE_OIDC_ISSUER=http://gorape.local:8080/realms/gorape`
  static ConnectionSettings defaultsFromEnvironment(RuntimePlatform platform) {
    const apiOverride = String.fromEnvironment('GORAPE_API_BASE_URL');
    const issuerOverride = String.fromEnvironment('GORAPE_OIDC_ISSUER');
    const clientIdOverride = String.fromEnvironment('GORAPE_OIDC_CLIENT_ID');
    const redirectOverride = String.fromEnvironment('GORAPE_OIDC_REDIRECT_URI');

    final base = defaultsFor(platform);
    return base.copyWith(
      apiBaseUrl: apiOverride.isEmpty ? null : apiOverride,
      issuer: issuerOverride.isEmpty ? null : issuerOverride,
      clientId: clientIdOverride.isEmpty ? null : clientIdOverride,
      redirectUri: redirectOverride.isEmpty ? null : redirectOverride,
      scopes: const ['openid', 'profile'],
    );
  }

  ConnectionSettings copyWith({
    String? apiBaseUrl,
    String? issuer,
    String? clientId,
    String? redirectUri,
    List<String>? scopes,
  }) {
    return ConnectionSettings(
      apiBaseUrl: _trimTrailingSlash(apiBaseUrl ?? this.apiBaseUrl),
      issuer: _trimTrailingSlash(issuer ?? this.issuer),
      clientId: (clientId ?? this.clientId).trim(),
      redirectUri: (redirectUri ?? this.redirectUri).trim(),
      scopes: scopes ?? this.scopes,
    );
  }

  bool get usesInsecureTransport {
    final api = Uri.tryParse(apiBaseUrl);
    final idp = Uri.tryParse(issuer);
    return api?.scheme == 'http' || idp?.scheme == 'http';
  }

  List<String> validate() {
    final errors = <String>[];
    final api = Uri.tryParse(apiBaseUrl);
    if (api == null || !api.hasScheme || api.host.isEmpty) {
      errors.add('Gorape API URL must be an absolute URL.');
    }
    final idp = Uri.tryParse(issuer);
    if (idp == null || !idp.hasScheme || idp.host.isEmpty) {
      errors.add('OIDC issuer must be an absolute URL.');
    }
    if (clientId.trim().isEmpty) {
      errors.add('OIDC client ID is required.');
    }
    if (redirectUri.trim().isEmpty) {
      errors.add('OIDC redirect URI is required.');
    }
    if (!scopes.contains('openid')) {
      errors.add('The openid scope is required.');
    }
    return errors;
  }

  Map<String, dynamic> toJson() => {
    'apiBaseUrl': apiBaseUrl,
    'issuer': issuer,
    'clientId': clientId,
    'redirectUri': redirectUri,
    'scopes': scopes,
  };

  factory ConnectionSettings.fromJson(Map<String, dynamic> json) {
    final defaults = defaultsFor(RuntimePlatform.unknown);
    return ConnectionSettings(
      apiBaseUrl: (json['apiBaseUrl'] as String?) ?? defaults.apiBaseUrl,
      issuer: (json['issuer'] as String?) ?? defaults.issuer,
      clientId: (json['clientId'] as String?) ?? defaults.clientId,
      redirectUri: (json['redirectUri'] as String?) ?? defaults.redirectUri,
      scopes:
          (json['scopes'] as List<dynamic>?)?.whereType<String>().toList(
            growable: false,
          ) ??
          defaults.scopes,
    );
  }

  String encode() => jsonEncode(toJson());

  factory ConnectionSettings.decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid connection settings');
    }
    return ConnectionSettings.fromJson(decoded);
  }

  static String _trimTrailingSlash(String value) {
    var result = value.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  @override
  bool operator ==(Object other) {
    return other is ConnectionSettings &&
        other.apiBaseUrl == apiBaseUrl &&
        other.issuer == issuer &&
        other.clientId == clientId &&
        other.redirectUri == redirectUri &&
        _listEquals(other.scopes, scopes);
  }

  @override
  int get hashCode => Object.hash(
    apiBaseUrl,
    issuer,
    clientId,
    redirectUri,
    Object.hashAll(scopes),
  );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
