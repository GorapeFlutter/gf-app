import '../core/config/connection_settings.dart';
import '../core/config/runtime_platform.dart';
import 'appauth_oidc_service.dart';
import 'oidc_service.dart';

OidcService createOidcService(
  ConnectionSettings settings,
  RuntimePlatform platform,
) {
  return switch (platform) {
    RuntimePlatform.android ||
    RuntimePlatform.ios ||
    RuntimePlatform.macos => AppAuthOidcService(settings: settings),
    RuntimePlatform.windows => const UnsupportedOidcService(
      'Windows向けflutter_appauth実装がありません。'
      'Authorization Code + PKCEをループバックリダイレクトで実装する必要があります。',
    ),
    RuntimePlatform.linux => const UnsupportedOidcService(
      'Linux向けflutter_appauth実装がありません。',
    ),
    RuntimePlatform.web => const UnsupportedOidcService(
      'このクライアントはWebを対象外としています。',
    ),
    RuntimePlatform.unknown => const UnsupportedOidcService(
      'プラットフォームを判定できないためOIDCを開始できません。',
    ),
  };
}
