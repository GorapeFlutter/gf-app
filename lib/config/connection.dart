import '../entity/model/connection.dart';
import '../entity/model/platform.dart';

abstract interface class ConnectionConfig {
  ConnectionSettings defaultsFor(RuntimePlatform platform);

  ConnectionSettings defaultsFromEnvironment(RuntimePlatform platform);
}

final class ConnectionConfigImpl implements ConnectionConfig {
  const ConnectionConfigImpl();

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

ConnectionConfig newConnectionConfig() => const ConnectionConfigImpl();
