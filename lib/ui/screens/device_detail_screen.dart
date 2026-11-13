import 'package:flutter/material.dart' hide Text;
import '../../l10n/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/providers.dart';
import '../../entity/model/device.dart';
import '../../entity/model/device_ref.dart';
import '../../entity/model/role.dart';
import '../widgets/common.dart';
import '../widgets/role_badge.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  const DeviceDetailScreen({
    super.key,
    required this.projectId,
    required this.deviceId,
    this.initialDevice,
  });

  final String projectId;
  final String deviceId;
  final Device? initialDevice;

  @override
  ConsumerState<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  bool _busy = false;
  Object? _actionError;

  DeviceRef get _refKey =>
      DeviceRef(projectId: widget.projectId, deviceId: widget.deviceId);

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(deviceDetailProvider(_refKey));
    final device = detail.value ?? widget.initialDevice;
    final attestations = ref.watch(attestationsProvider(_refKey));
    final localKey = ref.watch(localDeviceKeyProvider(_refKey));
    final role = ref.watch(projectRoleProvider(widget.projectId));
    final canEdit = role.canEdit;

    return Scaffold(
      appBar: AppBar(
        title: AppText(device?.displayName ?? 'デバイス詳細'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(child: RoleBadge(role: role)),
          ),
          IconButton(
            tooltip: tr(context, '再読み込み'),
            onPressed: _busy ? null : _refresh,
            icon: Icon(Icons.refresh, size: 22),
          ),
        ],
      ),
      body: device == null
          ? detail.hasError
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: ErrorCard(error: detail.error!, onRetry: _refresh),
                  )
                : const LoadingView()
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (_actionError != null) ...[
                    ErrorCard(error: _actionError!, compact: true),
                    const SizedBox(height: 12),
                  ],
                  if (!canEdit)
                    RoleNotice(
                      role: role,
                      scopeLabel: 'デバイス操作',
                      message: role == AccessRole.none
                          ? 'Keycloakトークンにこのプロジェクトのロールがありません。'
                                '参照はできますが、所有証明・失効は実行できません。'
                          : '閲覧者のため、所有証明とデバイス失効は実行できません。',
                    ),
                  SectionCard(
                    title: 'デバイス状態',
                    icon: Icons.verified_user_outlined,
                    trailing: StatusChip.status(context, device.status),
                    child: Column(
                      children: [
                        KeyValueRow('デバイスID', device.id, monospace: true),
                        KeyValueRow('プラットフォーム', platformLabel(device.platform)),
                        KeyValueRow(
                          '登録日時',
                          formatTimestamp(device.registeredAt),
                        ),
                        KeyValueRow(
                          '最終検証',
                          formatTimestamp(device.lastVerifiedAt),
                        ),
                        if (device.revokedAt != null)
                          KeyValueRow(
                            '失効日時',
                            formatTimestamp(device.revokedAt),
                          ),
                        KeyValueRow('バージョン', device.version.toString()),
                      ],
                    ),
                  ),
                  SectionCard(
                    title: 'この端末の鍵',
                    icon: Icons.key_outlined,
                    child: localKey.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (error, _) => AppText('$error'),
                      data: (key) => key == null
                          ? AppText(
                              'この端末には該当デバイスの秘密鍵がありません。\n'
                              '他端末で登録されたデバイスは表示・失効のみ可能です。',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          : Column(
                              children: [
                                KeyValueRow(
                                  'Key Identifier',
                                  key.keyIdentifier,
                                  monospace: true,
                                ),
                                KeyValueRow('Algorithm', key.algorithm),
                                KeyValueRow(
                                  'Security Level',
                                  key.securityLevel ?? '—',
                                ),
                                KeyValueRow(
                                  'ローカル登録',
                                  formatTimestamp(key.createdAt),
                                ),
                              ],
                            ),
                    ),
                  ),
                  SectionCard(
                    title: '操作',
                    icon: Icons.play_circle_outline,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed:
                              _busy ||
                                  !canEdit ||
                                  !device.isActive ||
                                  localKey.value == null
                              ? null
                              : _verifyPossession,
                          icon: _busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.vpn_key, size: 22),
                          label: const AppText('チャレンジ署名で所有証明'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _busy || !canEdit || !device.isActive
                              ? null
                              : _revokeDevice,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          icon: const Icon(Icons.block),
                          label: const AppText('デバイスを失効'),
                        ),
                        const SizedBox(height: 8),
                        AppText(
                          '所有証明ではBase64urlチャレンジを生バイト列に戻し、'
                          'OS保護鍵で署名します。ECDSAはASN.1 DER、'
                          'RSAはPKCS#1 v1.5/SHA-256、Ed25519は生バイト列です。',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  SectionCard(
                    title: 'Attestation記録',
                    icon: Icons.fact_check_outlined,
                    trailing: IconButton(
                      tooltip: tr(context, '最新の記録を取得'),
                      onPressed: _busy
                          ? null
                          : () => ref
                                .read(attestationsProvider(_refKey).notifier)
                                .reload(),
                      icon: Icon(Icons.refresh, size: 22),
                    ),
                    child: attestations.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (error, _) => ErrorCard(
                        error: error,
                        compact: true,
                        onRetry: () => ref
                            .read(attestationsProvider(_refKey).notifier)
                            .reload(),
                      ),
                      data: (records) => records.isEmpty
                          ? const AppText('Attestation記録はありません。')
                          : Column(
                              children: [
                                for (final record in records)
                                  Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: AppText(
                                                  record.attestationType,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.titleSmall,
                                                ),
                                              ),
                                              StatusChip.status(
                                                context,
                                                record.verificationStatus,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              StatusChip(
                                                label: record.securityLevel,
                                                color: switch (record
                                                    .securityLevel) {
                                                  'strongbox' => Colors.teal,
                                                  'trusted_environment' =>
                                                    Colors.green,
                                                  _ => Colors.orange,
                                                },
                                              ),
                                              AppText(
                                                record.verifierVersion,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.labelSmall,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          AppText(
                                            formatTimestamp(record.verifiedAt),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(deviceDetailProvider(_refKey));
    ref.invalidate(attestationsProvider(_refKey));
    ref.invalidate(localDeviceKeyProvider(_refKey));
    try {
      await ref.read(deviceDetailProvider(_refKey).future);
    } on Object {
      // The error is rendered by the provider state.
    }
  }

  Future<void> _verifyPossession() async {
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await ref
          .read(deviceControllerProvider)
          .provePossession(
            projectId: widget.projectId,
            deviceId: widget.deviceId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText('チャレンジ署名をGorapeが検証しました。')),
      );
      await _refresh();
    } on Object catch (error) {
      if (mounted) setState(() => _actionError = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revokeDevice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText('デバイスを失効しますか？'),
        content: const AppText(
          'Gorape側でデバイスがrevokedになります。\n'
          'この端末のローカル鍵も削除されます。元に戻せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AppText('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const AppText('失効する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await ref
          .read(deviceControllerProvider)
          .revoke(projectId: widget.projectId, deviceId: widget.deviceId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: AppText('デバイスを失効しました。')));
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) setState(() => _actionError = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
