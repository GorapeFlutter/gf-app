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
  /// GF-00932 — Initializes SettingsScreen.
  const SettingsScreen({
    super.key,
    this.fromLogin = false,
    this.embedded = false,
  });

  final bool fromLogin;
  final bool embedded;

  /// GF-00933 — Builds the widget or value for SettingsScreen.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionSettingsProvider);
    final content = connection.when(
      loading: /* GF-00934 — Runs an inline callback in SettingsScreen.build. */
          () => const LoadingView(label: '設定を読み込み中...'),
      error: /* GF-00935 — Runs an inline callback in SettingsScreen.build. */
          (error, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: ErrorCard(
              error: error,
              onRetry: /* GF-00936 — Runs an inline callback in SettingsScreen.build.callback. */
                  () => ref.invalidate(connectionSettingsProvider),
            ),
          ),
      data: /* GF-00937 — Runs an inline callback in SettingsScreen.build. */
          (settings) => _SettingsForm(settings: settings, fromLogin: fromLogin),
    );

    if (embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const AppText('接続設定')),
      body: content,
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  /// GF-00938 — Initializes _SettingsForm.
  const _SettingsForm({required this.settings, required this.fromLogin});

  final ConnectionSettings settings;
  final bool fromLogin;

  /// GF-00939 — Creates the state object for _SettingsForm.
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

  /// GF-00940 — Initializes state for _SettingsFormState.
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

  /// GF-00941 — Releases resources owned by _SettingsFormState.
  @override
  void dispose() {
    _apiController.dispose();
    _issuerController.dispose();
    _clientIdController.dispose();
    _redirectController.dispose();
    super.dispose();
  }

  /// GF-00942 — Computes _SettingsFormState._edited.
  ConnectionSettings get _edited => widget.settings.copyWith(
    apiBaseUrl: _apiController.text,
    issuer: _issuerController.text,
    clientId: _clientIdController.text,
    redirectUri: _redirectController.text,
  );

  /// GF-00943 — Builds the widget or value for _SettingsFormState.
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
            onChanged: /* GF-00944 — Runs an inline callback in _SettingsFormState.build. */ (value) {
              if (value == null) return;
              unawaited(
                ref.read(languageProvider.notifier).setLanguage(value).catchError(
                  /* GF-00945 — Runs an inline callback in _SettingsFormState.build.callback. */ (
                    Object error,
                  ) {
                    if (mounted)
                      setState(
                        /* GF-00946 — Runs an inline callback in _SettingsFormState.build.callback.callback. */ () =>
                            _error = error,
                      );
                  },
                ),
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
            onPressed: /* GF-00947 — Runs an inline callback in _SettingsFormState.build. */
                () => _copyRedirectUris(context, _edited),
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

  /// GF-00948 — Handles redirect allow list in _SettingsFormState.
  List<String> _redirectAllowList(ConnectionSettings settings) {
    return {'http://127.0.0.1:8400/callback', settings.redirectUri}
        .where(
          /* GF-00949 — Runs an inline callback in _SettingsFormState._redirectAllowList. */ (
            value,
          ) => value.isNotEmpty,
        )
        .toList(growable: false);
  }

  /// GF-00950 — Handles copy redirect uris in _SettingsFormState.
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

  /// GF-00951 — Handles save in _SettingsFormState.
  Future<void> _save() async {
    // GF-02113 — Clear feedback state and mark settings as saving.
    setState(
      /* GF-00952 — Runs an inline callback in _SettingsFormState._save. */ () {
        _saving = true;
        _error = null;
        _healthResult = null;
      },
    );
    try {
      // GF-02114 — Validate and persist connection settings through the controller.
      await ref.read(connectionSettingsProvider.notifier).save(_edited);
      if (!mounted) return;
      // GF-02115 — Confirm the saved settings to the user.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: AppText('接続設定を保存しました。')));
    } on Object catch (error) {
      // GF-02116 — Display validation or persistence errors.
      if (mounted)
        setState(
          /* GF-00953 — Runs an inline callback in _SettingsFormState._save. */ () =>
              _error = error,
        );
    } finally {
      // GF-02117 — Clear the saving state for every outcome.
      if (mounted)
        setState(
          /* GF-00954 — Runs an inline callback in _SettingsFormState._save. */ () =>
              _saving = false,
        );
    }
  }

  /// GF-00955 — Handles reset in _SettingsFormState.
  Future<void> _reset() async {
    // GF-02118 — Start reset feedback and prevent concurrent settings actions.
    setState(
      /* GF-00956 — Runs an inline callback in _SettingsFormState._reset. */ () {
        _saving = true;
        _error = null;
        _healthResult = null;
      },
    );
    try {
      // GF-02119 — Remove the saved override and load platform defaults.
      await ref.read(connectionSettingsProvider.notifier).reset();
      final settings = ref.read(connectionSettingsProvider).value;
      if (settings != null) {
        // GF-02120 — Synchronize all text fields with the reset configuration.
        _apiController.text = settings.apiBaseUrl;
        _issuerController.text = settings.issuer;
        _clientIdController.text = settings.clientId;
        _redirectController.text = settings.redirectUri;
      }
      if (!mounted) return;
      // GF-02121 — Confirm that defaults have been restored.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: AppText('初期値に戻しました。')));
    } on Object catch (error) {
      // GF-02122 — Display reset failures without discarding the form.
      if (mounted)
        setState(
          /* GF-00957 — Runs an inline callback in _SettingsFormState._reset. */ () =>
              _error = error,
        );
    } finally {
      // GF-02123 — Clear the saving state for every outcome.
      if (mounted)
        setState(
          /* GF-00958 — Runs an inline callback in _SettingsFormState._reset. */ () =>
              _saving = false,
        );
    }
  }

  /// GF-00959 — Handles check health in _SettingsFormState.
  Future<void> _checkHealth() async {
    // GF-02124 — Start the health check and clear stale results.
    setState(
      /* GF-00960 — Runs an inline callback in _SettingsFormState._checkHealth. */ () {
        _checkingHealth = true;
        _healthResult = null;
        _error = null;
      },
    );
    try {
      // GF-02125 — Query the configured Gorape endpoint.
      final body = await ref.read(connectionHealthControllerProvider).check();
      if (!mounted) return;
      // GF-02126 — Format and show the health response.
      setState(
        /* GF-00961 — Runs an inline callback in _SettingsFormState._checkHealth. */ () {
          _healthResult =
              '応答: ${body['service'] ?? 'unknown'} / '
              '${body['status'] ?? 'unknown'}';
        },
      );
    } on Object catch (error) {
      // GF-02127 — Display health-check transport or API errors.
      if (mounted)
        setState(
          /* GF-00962 — Runs an inline callback in _SettingsFormState._checkHealth. */ () =>
              _error = error,
        );
    } finally {
      // GF-02128 — Clear the health-check progress state.
      if (mounted)
        setState(
          /* GF-00963 — Runs an inline callback in _SettingsFormState._checkHealth. */ () =>
              _checkingHealth = false,
        );
    }
  }

  /// GF-00964 — Handles sign out in _SettingsFormState.
  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
  }
}
