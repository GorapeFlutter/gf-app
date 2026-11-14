import '../entity/model/connection.dart';
import '../entity/model/platform.dart';

abstract interface class ConnectionConfig {
  /// GF-00111 — Handles defaults for in ConnectionConfig.
  ConnectionSettings defaultsFor(RuntimePlatform platform);

  /// GF-00112 — Handles defaults from environment in ConnectionConfig.
  ConnectionSettings defaultsFromEnvironment(RuntimePlatform platform);
}

final class ConnectionConfigImpl implements ConnectionConfig {
  /// GF-00113 — Initializes ConnectionConfigImpl.
  const ConnectionConfigImpl();

  /// GF-00114 — Handles defaults for in ConnectionConfigImpl.
  @override
  ConnectionSettings defaultsFor(RuntimePlatform platform) {
    return ConnectionSettings(
      // Android emulators reach the host through 10.0.2.2. The issuer stays
      // on localhost so it remains identical to Keycloak's `iss` claim.
      apiBaseUrl: platform == RuntimePlatform.android
          ? 'http://10.0.2.2:8000'
          : 'http://localhost:8000',
      issuer: 'http://localhost:8080/realms/gorape',
      clientId: 'gorape-client',
      redirectUri: ConnectionSettings.flutterRedirectUri,
    );
  }

  /// GF-00115 — Handles defaults from environment in ConnectionConfigImpl.
  @override
  ConnectionSettings defaultsFromEnvironment(RuntimePlatform platform) {
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
}

/// GF-00116 — Creates an instance for new connection config.
ConnectionConfig newConnectionConfig() => const ConnectionConfigImpl();
