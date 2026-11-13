import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/device.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(device?.displayName ?? 'デバイス詳細'),
        actions: [
          IconButton(
            tooltip: '再読み込み',
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
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
                      error: (error, _) => Text('$error'),
                      data: (key) => key == null
                          ? Text(
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
                              : const Icon(Icons.fingerprint),
                          label: const Text('チャレンジ署名で所有証明'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _busy || !device.isActive
                              ? null
                              : _revokeDevice,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          icon: const Icon(Icons.block),
                          label: const Text('デバイスを失効'),
                        ),
                        const SizedBox(height: 8),
                        Text(
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
                      tooltip: '最新の記録を取得',
                      onPressed: _busy
                          ? null
                          : () => ref
                                .read(attestationsProvider(_refKey).notifier)
                                .reload(),
                      icon: const Icon(Icons.refresh),
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
                          ? const Text('Attestation記録はありません。')
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
                                                child: Text(
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
                                              Text(
                                                record.verifierVersion,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.labelSmall,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
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
          .read(deviceActionsProvider)
          .provePossession(
            projectId: widget.projectId,
            deviceId: widget.deviceId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('チャレンジ署名をGorapeが検証しました。')));
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
        title: const Text('デバイスを失効しますか？'),
        content: const Text(
          'Gorape側でデバイスがrevokedになります。\n'
          'この端末のローカル鍵も削除されます。元に戻せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('失効する'),
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
          .read(deviceActionsProvider)
          .revoke(projectId: widget.projectId, deviceId: widget.deviceId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('デバイスを失効しました。')));
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) setState(() => _actionError = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
