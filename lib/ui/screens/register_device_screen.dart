import 'package:flutter/material.dart' hide Text;
import '../../l10n/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/providers.dart';
import '../../entity/model/platform_support.dart';
import '../../entity/model/role.dart';
import '../../entity/response/attestation.dart';
import '../widgets/common.dart';
import '../widgets/role_badge.dart';

class RegisterDeviceScreen extends ConsumerStatefulWidget {
  const RegisterDeviceScreen({
    super.key,
    required this.projectId,
    required this.onRegistered,
    required this.onOpenDevices,
  });

  final String projectId;
  final void Function(String deviceId) onRegistered;
  final VoidCallback onOpenDevices;

  @override
  ConsumerState<RegisterDeviceScreen> createState() =>
      _RegisterDeviceScreenState();
}

class _RegisterDeviceScreenState extends ConsumerState<RegisterDeviceScreen> {
  final _nameController = TextEditingController();
  bool _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _nameController.text = '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platform = ref.watch(runtimePlatformProvider);
    final support = ref.watch(platformSupportProvider);
    final devicePlatform = ref.watch(devicePlatformProvider);
    final availability = ref.watch(deviceKeyAvailabilityProvider);
    final capabilities = ref.watch(capabilitiesProvider(widget.projectId));
    final role = ref.watch(projectRoleProvider(widget.projectId));
    final caps = capabilities.value ?? const AttestationCapabilities({});
    final backendStatus = caps.statusFor(devicePlatform);
    final backendReady = backendStatus == 'implemented';
    final localReady = availability.value?.supported == true;
    final canRegister =
        !_busy &&
        role.canEdit &&
        localReady &&
        backendReady &&
        _nameController.text.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppText('Android端末を登録', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        AppText(
          'サーバーのチャレンジをOS鍵生成にバインドし、公開鍵と'
          'Key Attestation証明書チェーンをGorapeへ送信します。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (!role.canEdit)
          RoleNotice(
            role: role,
            scopeLabel: 'デバイス登録',
            message: role == AccessRole.none
                ? 'Keycloakトークンにこのプロジェクトのロールがありません。'
                      'Gorape側でeditor権限があっても、UIからは登録できません。'
                : '閲覧者のためデバイスを登録できません。管理者または編集者のロールが必要です。',
          ),
        if (_error != null) ...[
          ErrorCard(error: _error!, compact: true),
          const SizedBox(height: 12),
        ],
        SectionCard(
          title: 'この端末',
          icon: Icons.phone_android,
          trailing: StatusChip(
            label: platform.displayName,
            color: Theme.of(context).colorScheme.primary,
          ),
          child: availability.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => ErrorCard(error: error, compact: true),
            data: (value) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CheckLine(
                  label: 'Keycloakログイン',
                  ok: support.oidcLogin,
                  detail: 'Authorization Code + PKCE',
                ),
                _CheckLine(
                  label: 'OS保護鍵の生成',
                  ok: value.supported,
                  detail: value.supported
                      ? '${value.hardwareBacked ? "ハードウェア" : "ソフトウェア"}鍵 '
                            '${value.securityLevel ?? ""}'
                      : value.reason ?? '未対応',
                ),
                _CheckLine(
                  label: 'Attestation証拠',
                  ok: value.attestationSupported,
                  detail: value.attestationSupported
                      ? '証明書チェーン（leaf-first）'
                      : 'このビルドでは取得できません',
                ),
                const SizedBox(height: 8),
                AppText(
                  support.note,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        SectionCard(
          title: 'Gorapeバックエンド',
          icon: Icons.cloud_outlined,
          trailing: IconButton(
            tooltip: tr(context, 'Verifier対応状況を更新'),
            onPressed: _busy
                ? null
                : () => ref
                      .read(capabilitiesProvider(widget.projectId).notifier)
                      .reload(),
            icon: Icon(Icons.refresh, size: 22),
          ),
          child: capabilities.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => ErrorCard(
              error: error,
              compact: true,
              onRetry: () => ref
                  .read(capabilitiesProvider(widget.projectId).notifier)
                  .reload(),
            ),
            data: (value) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in const [
                  'android',
                  'windows',
                  'ios',
                  'macos',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: AppText(platformLabel(entry)),
                        ),
                        StatusChip.status(context, value.statusFor(entry)),
                        const Spacer(),
                        AppText(
                          entry == devicePlatform ? 'この端末' : '',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                if (backendStatus == 'unconfigured') ...[
                  const SizedBox(height: 10),
                  AppText(
                    'Android verifierは "unconfigured" です。Gorapeの '
                    'android_trust_anchors にGoogle Hardware Attestation Root CAを'
                    '設定するまで登録は失敗します。',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SectionCard(
          title: '登録情報',
          icon: Icons.edit_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                enabled: !_busy,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: tr(context, '表示名'),
                  hintText: tr(context, '例: Pixel 8 Pro'),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: canRegister ? _register : null,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.add, size: 22),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: AppText(_busy ? '登録しています...' : 'チャレンジを取得して登録'),
                ),
              ),
              if (!localReady)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AppText(
                    'このOSではOS保護鍵とAttestationが未実装のため登録できません。',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (!role.canEdit)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AppText(
                    'デバイス登録にはプロジェクトのeditor以上のロールが必要です。',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (!backendReady)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AppText(
                    'Gorapeバックエンドのverifierが "implemented" ではないため登録できません。',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.help_outline),
            title: const AppText('登録フローの詳細'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const _FlowStep(
                '1',
                'POST /devices/registration/challenge で単一使用チャレンジを取得',
              ),
              const _FlowStep('2', 'Base64urlを生バイト列へデコード'),
              const _FlowStep(
                '3',
                'KeyGenParameterSpec.setAttestationChallenge に同じバイト列を設定',
              ),
              const _FlowStep('4', 'EC P-256公開鍵と証明書チェーン（leaf-first）を送信'),
              const _FlowStep(
                '5',
                'POST /devices/registration/verify が422なら信頼アンカーを確認',
              ),
              const SizedBox(height: 8),
              AppText(
                PlatformSupport.passkeyDelegationNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _register() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(deviceControllerProvider)
          .register(
            projectId: widget.projectId,
            displayName: _nameController.text,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.verified_user),
          title: const AppText('デバイスを登録しました'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyValueRow('表示名', result.device.displayName),
              KeyValueRow('Security Level', result.securityLevel ?? '—'),
              KeyValueRow('Device ID', result.device.id, monospace: true),
              const SizedBox(height: 8),
              const AppText(
                'バックエンドがAttestationをverifiedとして記録しました。'
                '続けてチャレンジ署名による所有証明を実行できます。',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const AppText('一覧へ'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onRegistered(result.device.id);
              },
              child: const AppText('デバイス一覧を開く'),
            ),
          ],
        ),
      );
      if (mounted) widget.onRegistered(result.device.id);
      _nameController.clear();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({
    required this.label,
    required this.ok,
    required this.detail,
  });

  final String label;
  final bool ok;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel_outlined,
            size: 18,
            color: ok ? Colors.green : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(label),
                AppText(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep(this.number, this.text);

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            child: AppText(number, style: const TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(child: AppText(text)),
        ],
      ),
    );
  }
}
