import 'package:flutter/material.dart' hide Text;
import '../../l10n/app_text.dart';

import '../../entity/model/auth_session.dart';
import '../../entity/model/connection.dart';
import '../../entity/model/platform.dart';
import '../../entity/model/platform_support.dart';
import '../widgets/common.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.settings,
    required this.platform,
    required this.support,
    required this.oidcSupported,
    required this.loading,
    required this.onLogin,
    required this.onAdminLogin,
    required this.onOpenSettings,
    this.error,
    this.unsupportedReason,
    this.session,
  });

  final ConnectionSettings? settings;
  final RuntimePlatform platform;
  final PlatformSupport support;
  final bool oidcSupported;
  final bool loading;
  final VoidCallback onLogin;
  final VoidCallback onAdminLogin;
  final VoidCallback onOpenSettings;
  final Object? error;
  final String? unsupportedReason;
  final AuthSession? session;

  static const registrationUrl =
      'http://localhost:8080/realms/gorape/protocol/openid-connect/registrations'
      '?client_id=gorape-client'
      '&redirect_uri=com.gorapeflutter.gfapp:/oauth2redirect'
      '&response_type=code&scope=openid';

  void _showRegistrationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText('アカウント登録'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText('以下のURLをブラウザで開いてアカウントを登録してください。'),
            SizedBox(height: 12),
            SelectableText(registrationUrl),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const AppText('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configuration = settings;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: AspectRatio(
                        aspectRatio: 3,
                        child: Image.asset(
                          'assets/gorape/brand/gorape_header.png',
                          fit: BoxFit.contain,
                          semanticLabel: 'Gorape',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    'Keycloakでサインインし、OS保護鍵をGorapeに登録します。\n'
                    'パスキーとMFAはKeycloak、デバイス検証はGorapeが担当します。',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (error != null) ...[
                    ErrorCard(error: error!, compact: true),
                    const SizedBox(height: 16),
                  ],
                  if (session != null) ...[
                    Card(
                      color: theme.colorScheme.secondaryContainer,
                      child: ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: AppText(session!.displayName),
                        subtitle: AppText(
                          '${session!.email ?? session!.subject}\n'
                          'Issuer: ${session!.issuer ?? configuration?.issuer ?? '—'}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: !oidcSupported || loading ? null : onLogin,
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: AppText(
                        loading ? 'Keycloakへ接続中...' : 'Keycloakでログイン',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: !oidcSupported || loading ? null : onAdminLogin,
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const AppText('管理者ログイン'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppText(
                    '管理者機能を使う場合は、管理者ロールを持つKeycloakアカウントでログインしてください。'
                    '権限を切り替える場合は、ログアウトしてから再ログインしてください。',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _showRegistrationDialog(context),
                    icon: const Icon(Icons.person_add_alt, size: 22),
                    label: const AppText('アカウント登録'),
                  ),
                  if (!oidcSupported) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: theme.colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              '${platform.displayName}ではログイン未対応です',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            AppText(
                              unsupportedReason ?? support.note,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (configuration != null)
                    SectionCard(
                      title: '接続先',
                      icon: Icons.dns_outlined,
                      trailing: IconButton(
                        tooltip: tr(context, '接続設定を開く'),
                        onPressed: onOpenSettings,
                        icon: const Icon(Icons.tune),
                      ),
                      child: Column(
                        children: [
                          KeyValueRow(
                            'Gorape API',
                            configuration.apiBaseUrl,
                            monospace: true,
                          ),
                          KeyValueRow(
                            'OIDC Issuer',
                            configuration.issuer,
                            monospace: true,
                          ),
                          KeyValueRow(
                            'Client ID',
                            configuration.clientId,
                            monospace: true,
                          ),
                          KeyValueRow(
                            'Redirect URI',
                            configuration.redirectUri,
                            monospace: true,
                          ),
                          const SizedBox(height: 8),
                          if (configuration.usesInsecureTransport)
                            AppText(
                              'HTTPの開発用接続です。本番ではHTTPSを使用してください。',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          if (platform == RuntimePlatform.android)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: AppText(
                                'Android Emulatorでは OIDC 用に '
                                '`adb reverse tcp:8080 tcp:8080` を実行してください。'
                                'APIは既定で 10.0.2.2:8000 を利用します。',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Card(
                    child: ExpansionTile(
                      leading: Icon(Icons.info, size: 22),
                      title: const AppText('OS別の対応状況'),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        _SupportLine(
                          label: 'Keycloakログイン',
                          supported: support.oidcLogin,
                        ),
                        _SupportLine(
                          label: 'OS保護鍵の生成',
                          supported: support.localKeyGeneration,
                        ),
                        _SupportLine(
                          label: 'Attestation（バックエンド）',
                          supported: support.attestationFlow,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AppText(
                            support.note,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AppText(
                            PlatformSupport.passkeyDelegationNote,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onOpenSettings,
                    icon: Icon(Icons.settings, size: 22),
                    label: const AppText('接続設定・Redirect URI'),
                  ),
                  AppText(
                    'Access TokenのみをGorape APIへ送信します。ID TokenはAPI認証情報として使用しません。',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportLine extends StatelessWidget {
  const _SupportLine({required this.label, required this.supported});

  final String label;
  final bool supported;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            supported ? Icons.check_circle : Icons.remove_circle_outline,
            size: 16,
            color: supported
                ? Colors.green
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(child: AppText(label)),
          AppText(
            supported ? '対応' : '未対応',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
