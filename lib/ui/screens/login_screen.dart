import 'package:flutter/material.dart';

import '../../auth/auth_session.dart';
import '../../core/config/connection_settings.dart';
import '../../core/config/runtime_platform.dart';
import '../../platform/platform_support.dart';
import '../widgets/common.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.settings,
    required this.platform,
    required this.oidcSupported,
    required this.loading,
    required this.onLogin,
    required this.onOpenSettings,
    this.error,
    this.unsupportedReason,
    this.session,
  });

  final ConnectionSettings? settings;
  final RuntimePlatform platform;
  final bool oidcSupported;
  final bool loading;
  final VoidCallback onLogin;
  final VoidCallback onOpenSettings;
  final Object? error;
  final String? unsupportedReason;
  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final support = PlatformSupport.forRuntime(platform);
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
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 42,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Gorape Device Trust',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
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
                        title: Text(session!.displayName),
                        subtitle: Text(
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
                      child: Text(
                        loading ? 'Keycloakへ接続中...' : 'Keycloakでログイン',
                      ),
                    ),
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
                            Text(
                              '${platform.displayName}ではログイン未対応です',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
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
                        tooltip: '接続設定を開く',
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
                            Text(
                              'HTTPの開発用接続です。本番ではHTTPSを使用してください。',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          if (platform == RuntimePlatform.android)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
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
                      leading: const Icon(Icons.info_outline),
                      title: const Text('OS別の対応状況'),
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
                          child: Text(
                            support.note,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
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
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('接続設定・Redirect URI'),
                  ),
                  Text(
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
          Expanded(child: Text(label)),
          Text(
            supported ? '対応' : '未対応',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
