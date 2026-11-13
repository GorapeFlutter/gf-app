import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/providers.dart';
import '../../entity/model/connection.dart';
import '../../entity/model/platform.dart';
import '../../l10n/app_text.dart';
import '../widgets/common.dart';

/// Connection, OIDC and Keycloak redirect configuration.
///
/// Values are stored locally; they are not part of the Gorape API contract.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    super.key,
    this.fromLogin = false,
    this.embedded = false,
  });

  final bool fromLogin;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionSettingsProvider);
    final content = connection.when(
      loading: () => const LoadingView(label: '設定を読み込み中...'),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorCard(
          error: error,
          onRetry: () => ref.invalidate(connectionSettingsProvider),
        ),
      ),
      data: (settings) =>
          _SettingsForm(settings: settings, fromLogin: fromLogin),
    );

    if (embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const AppText('接続設定')),
      body: content,
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.settings, required this.fromLogin});

  final ConnectionSettings settings;
  final bool fromLogin;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late final TextEditingController _apiController;
  late final TextEditingController _issuerController;
  late final TextEditingController _clientIdController;
  late final TextEditingController _redirectController;
  bool _saving = false;
  bool _checkingHealth = false;
  String? _healthResult;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _apiController = TextEditingController(text: widget.settings.apiBaseUrl);
    _issuerController = TextEditingController(text: widget.settings.issuer);
    _clientIdController = TextEditingController(text: widget.settings.clientId);
    _redirectController = TextEditingController(
      text: widget.settings.redirectUri,
    );
  }

  @override
  void dispose() {
    _apiController.dispose();
    _issuerController.dispose();
    _clientIdController.dispose();
    _redirectController.dispose();
    super.dispose();
  }

  ConnectionSettings get _edited => widget.settings.copyWith(
    apiBaseUrl: _apiController.text,
    issuer: _issuerController.text,
    clientId: _clientIdController.text,
    redirectUri: _redirectController.text,
  );

  @override
  Widget build(BuildContext context) {
    final platform = ref.watch(runtimePlatformProvider);
    final language = ref.watch(languageProvider).value?.languageCode ?? 'ja';
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: tr(context, '表示言語'),
          icon: Icons.language,
          child: DropdownButtonFormField<String>(
            key: ValueKey(language),
            initialValue: language,
            decoration: InputDecoration(labelText: tr(context, '言語')),
            items: [
              DropdownMenuItem(value: 'ja', child: const AppText('日本語')),
              DropdownMenuItem(value: 'en', child: const AppText('English')),
            ],
            onChanged: (value) {
              if (value == null) return;
              unawaited(
                ref
                    .read(languageProvider.notifier)
                    .setLanguage(value)
                    .catchError((Object error) {
                      if (mounted) setState(() => _error = error);
                    }),
              );
            },
          ),
        ),
        AppText('接続設定', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        AppText(
          'この端末: ${platform.displayName}。'
          'OIDC IssuerはKeycloakが発行する iss クレームと完全に一致する必要があります。',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (_error != null) ...[
          ErrorCard(error: _error!, compact: true),
          const SizedBox(height: 12),
        ],
        SectionCard(
          title: 'Gorape API',
          icon: Icons.dns_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _apiController,
                enabled: !_saving,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'API Base URL',
                  hintText: 'http://10.0.2.2:8000',
                  prefixIcon: Icon(Icons.extension, size: 22),
                ),
              ),
              const SizedBox(height: 8),
              if (platform == RuntimePlatform.android)
                AppText(
                  'Android Emulatorは 10.0.2.2、実機はPCのLAN IPを指定してください。'
                  'adb reverse を使う場合は localhost:8000 も利用できます。',
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _checkHealth,
                  icon: _checkingHealth
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.monitor_heart_outlined),
                  label: const AppText('ヘルスチェック'),
                ),
              ),
              if (_healthResult != null) ...[
                const SizedBox(height: 8),
                AppText(_healthResult!, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
        SectionCard(
          title: 'Keycloak / OIDC',
          icon: Icons.vpn_key_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _issuerController,
                enabled: !_saving,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'OIDC Issuer',
                  hintText: 'http://localhost:8080/realms/gorape',
                  prefixIcon: Icon(Icons.public),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _clientIdController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Client ID',
                  hintText: 'gorape-client',
                  prefixIcon: Icon(Icons.app_registration),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _redirectController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Redirect URI',
                  hintText: ConnectionSettings.flutterRedirectUri,
                  prefixIcon: Icon(Icons.call_received),
                ),
              ),
              const SizedBox(height: 12),
              AppText(
                'Authorization Code + PKCE（S256）、scopes: openid profile、'
                'audience: gorape-api。Gorape APIにはAccess Tokenのみを使用し、'
                'ID Tokenは送信しません。',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Keycloak Redirect URI許可リスト',
          icon: Icons.rule_outlined,
          trailing: IconButton(
            tooltip: tr(context, 'コピー'),
            onPressed: () => _copyRedirectUris(context, _edited),
            icon: const Icon(Icons.copy_all_outlined),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Keycloakの gorape-client に以下を登録してください。'
                '既存CLI用の http://127.0.0.1:8400/callback は変更・削除しません。',
              ),
              const SizedBox(height: 8),
              for (final uri in _redirectAllowList(_edited))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: SelectableText(
                    uri,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              AppText(
                'ローカルKeycloakの例: admin CLIで clients/gorape-client の '
                'redirectUris に追加します。詳細は README を参照してください。',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (_edited.usesInsecureTransport)
          Card(
            color: scheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: AppText(
                'HTTP接続はローカル開発専用です。本番ではHTTPSと'
                '正規のRedirect URIを使用してください。',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: AppText(_saving ? '保存中...' : '保存'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _saving ? null : _reset,
              icon: const Icon(Icons.restart_alt),
              label: const AppText('初期値に戻す'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'セッション',
          icon: Icons.logout,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                widget.fromLogin
                    ? 'ログイン前に接続先を確認できます。保存後に戻ってログインしてください。'
                    : 'ログアウトするとKeycloakのセッション終了を試行し、'
                          'ローカルのトークンを削除します。',
                style: theme.textTheme.bodySmall,
              ),
              if (!widget.fromLogin) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _signOut,
                  icon: Icon(Icons.history, size: 22),
                  label: const AppText('ログアウト'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        AppText(
          'Access TokenはGorape APIのBearer認証にのみ使用します。'
          'デバイス秘密鍵はOSキーストアから出ません。',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline),
        ),
      ],
    );
  }

  List<String> _redirectAllowList(ConnectionSettings settings) {
    return {
      'http://127.0.0.1:8400/callback',
      settings.redirectUri,
    }.where((value) => value.isNotEmpty).toList(growable: false);
  }

  Future<void> _copyRedirectUris(
    BuildContext context,
    ConnectionSettings settings,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: _redirectAllowList(settings).join('\n')),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: AppText('Redirect URIをコピーしました。')));
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _healthResult = null;
    });
    try {
      await ref.read(connectionSettingsProvider.notifier).save(_edited);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: AppText('接続設定を保存しました。')));
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reset() async {
    setState(() {
      _saving = true;
      _error = null;
      _healthResult = null;
    });
    try {
      await ref.read(connectionSettingsProvider.notifier).reset();
      final settings = ref.read(connectionSettingsProvider).value;
      if (settings != null) {
        _apiController.text = settings.apiBaseUrl;
        _issuerController.text = settings.issuer;
        _clientIdController.text = settings.clientId;
        _redirectController.text = settings.redirectUri;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: AppText('初期値に戻しました。')));
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _checkHealth() async {
    setState(() {
      _checkingHealth = true;
      _healthResult = null;
      _error = null;
    });
    try {
      final body = await ref.read(connectionHealthControllerProvider).check();
      if (!mounted) return;
      setState(() {
        _healthResult =
            '応答: ${body['service'] ?? 'unknown'} / '
            '${body['status'] ?? 'unknown'}';
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _checkingHealth = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
  }
}
