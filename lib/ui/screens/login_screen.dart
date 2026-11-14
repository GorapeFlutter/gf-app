import 'package:flutter/material.dart' hide Text;
import '../../config/langages/app_text.dart';

import '../../entity/model/auth_session.dart';
import '../../entity/model/connection.dart';
import '../../entity/model/platform.dart';
import '../../entity/model/platform_support.dart';
import '../widgets/common.dart';

class LoginScreen extends StatelessWidget {
  /// GF-00824 — Initializes LoginScreen.
  const LoginScreen({
    super.key,
    required this.settings,
    required this.platform,
    required this.support,
    required this.oidcSupported,
    required this.loading,
    required this.onLogin,
    required this.onPasskeyLogin,
    required this.onRegisterPasskey,
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
  final VoidCallback onPasskeyLogin;
  final Future<bool> Function() onRegisterPasskey;
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

  /// GF-00825 — Handles show registration dialog in LoginScreen.
  void _showRegistrationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: /* GF-00826 — Runs an inline callback in LoginScreen._showRegistrationDialog. */
          (context) => AlertDialog(
            title: const AppText('MCODE-00061'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText('MCODE-00063'),
                SizedBox(height: 12),
                SelectableText(registrationUrl),
              ],
            ),
            actions: [
              TextButton(
                onPressed: /* GF-00827 — Runs an inline callback in LoginScreen._showRegistrationDialog.callback. */
                    () => Navigator.of(context).pop(),
                child: const AppText('MCODE-00062'),
              ),
            ],
          ),
    );
  }

  /// GF-00828 — Builds the widget or value for LoginScreen.
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
                    'MCODE-00462',
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
                      child: AppText(loading ? 'MCODE-00067' : 'MCODE-00065'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: !oidcSupported || loading
                        ? null
                        : onPasskeyLogin,
                    icon: const Icon(Icons.fingerprint),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const AppText('MCODE-00505'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: !oidcSupported || loading
                        ? null
                        : () async {
                            try {
                              final registered = await onRegisterPasskey();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: AppText(
                                    registered ? 'MCODE-00506' : 'MCODE-00507',
                                  ),
                                ),
                              );
                            } on Object catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: AppText('$error')),
                              );
                            }
                          },
                    icon: const Icon(Icons.key_outlined),
                    label: const AppText('MCODE-00504'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: !oidcSupported || loading ? null : onAdminLogin,
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const AppText('MCODE-00066'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppText(
                    'MCODE-00463',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: /* GF-00829 — Runs an inline callback in LoginScreen.build. */
                        () => _showRegistrationDialog(context),
                    icon: const Icon(Icons.person_add_alt, size: 22),
                    label: const AppText('MCODE-00061'),
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
                      title: 'MCODE-00072',
                      icon: Icons.dns_outlined,
                      trailing: IconButton(
                        tooltip: tr(context, '接続設定を開く'),
                        onPressed: onOpenSettings,
                        icon: const Icon(Icons.tune),
                      ),
                      child: Column(
                        children: [
                          KeyValueRow(
                            'MCODE-00073',
                            configuration.apiBaseUrl,
                            monospace: true,
                          ),
                          KeyValueRow(
                            'MCODE-00076',
                            configuration.issuer,
                            monospace: true,
                          ),
                          KeyValueRow(
                            'MCODE-00077',
                            configuration.clientId,
                            monospace: true,
                          ),
                          KeyValueRow(
                            'MCODE-00078',
                            configuration.redirectUri,
                            monospace: true,
                          ),
                          const SizedBox(height: 8),
                          if (configuration.usesInsecureTransport)
                            AppText(
                              'MCODE-00095',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          if (platform == RuntimePlatform.android)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: AppText(
                                'MCODE-00484',
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
                      title: const AppText('MCODE-00069'),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        _SupportLine(
                          label: 'MCODE-00176',
                          supported: support.oidcLogin,
                        ),
                        _SupportLine(
                          label: 'MCODE-00475',
                          supported: support.passkeyCeremony,
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
                    label: const AppText('MCODE-00059'),
                  ),
                  AppText(
                    'MCODE-00416',
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
  /// GF-00830 — Initializes _SupportLine.
  const _SupportLine({required this.label, required this.supported});

  final String label;
  final bool supported;

  /// GF-00831 — Builds the widget or value for _SupportLine.
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
            supported ? 'MCODE-00070' : 'MCODE-00071',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
