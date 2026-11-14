import 'package:flutter/material.dart' hide Text;
import '../../config/langages/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../back/controller/providers.dart';
import '../../entity/model/device.dart';
import '../../entity/model/device_ref.dart';
import '../../entity/model/role.dart';
import '../widgets/common.dart';
import '../widgets/role_badge.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  /// GF-00717 — Initializes DeviceDetailScreen.
  const DeviceDetailScreen({
    super.key,
    required this.projectId,
    required this.deviceId,
    this.initialDevice,
  });

  final String projectId;
  final String deviceId;
  final Device? initialDevice;

  /// GF-00718 — Creates the state object for DeviceDetailScreen.
  @override
  ConsumerState<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  bool _busy = false;
  Object? _actionError;

  /// GF-00719 — Computes _DeviceDetailScreenState._refKey.
  DeviceRef get _refKey =>
      DeviceRef(projectId: widget.projectId, deviceId: widget.deviceId);

  /// GF-00720 — Builds the widget or value for _DeviceDetailScreenState.
  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(deviceDetailProvider(_refKey));
    final device = detail.value ?? widget.initialDevice;
    final attestations = ref.watch(attestationsProvider(_refKey));
    final role = ref.watch(projectRoleProvider(widget.projectId));
    final canEdit = role.canEdit;
    final session = ref.watch(authControllerProvider).value;
    final canProve = canEdit && (session?.isPasskeyAuthenticated ?? false);

    return Scaffold(
      appBar: AppBar(
        title: AppText(device?.displayName ?? 'MCODE-00123'),
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
                      scopeLabel: 'MCODE-00125',
                      message: role == AccessRole.none
                          ? 'Keycloakトークンにこのプロジェクトのロールがありません。'
                                '参照はできますが、所有証明・失効は実行できません。'
                          : '閲覧者のため、所有証明とデバイス失効は実行できません。',
                    ),
                  if (canEdit && !canProve)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: AppText('MCODE-00508'),
                      ),
                    ),
                  SectionCard(
                    title: 'MCODE-00128',
                    icon: Icons.verified_user_outlined,
                    trailing: StatusChip.status(context, device.status),
                    child: Column(
                      children: [
                        KeyValueRow('MCODE-00129', device.id, monospace: true),
                        KeyValueRow(
                          'MCODE-00130',
                          platformLabel(device.platform),
                        ),
                        KeyValueRow(
                          'MCODE-00131',
                          formatTimestamp(device.registeredAt),
                        ),
                        KeyValueRow(
                          'MCODE-00132',
                          formatTimestamp(device.lastVerifiedAt),
                        ),
                        if (device.revokedAt != null)
                          KeyValueRow(
                            'MCODE-00133',
                            formatTimestamp(device.revokedAt),
                          ),
                        KeyValueRow('MCODE-00134', device.version.toString()),
                      ],
                    ),
                  ),
                  SectionCard(
                    title: 'MCODE-00476',
                    icon: Icons.key_outlined,
                    child: const AppText('MCODE-00464'),
                  ),
                  SectionCard(
                    title: 'MCODE-00137',
                    icon: Icons.play_circle_outline,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: _busy || !canProve || !device.isActive
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
                          label: const AppText('MCODE-00442'),
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
                          label: const AppText('MCODE-00139'),
                        ),
                        const SizedBox(height: 8),
                        AppText(
                          'MCODE-00465',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  SectionCard(
                    title: 'MCODE-00142',
                    icon: Icons.fact_check_outlined,
                    trailing: IconButton(
                      tooltip: tr(context, '最新の記録を取得'),
                      onPressed: _busy
                          ? null
                          : /* GF-00724 — Runs an inline callback in _DeviceDetailScreenState.build. */ () =>
                                ref
                                    .read(
                                      attestationsProvider(_refKey).notifier,
                                    )
                                    .reload(),
                      icon: Icon(Icons.refresh, size: 22),
                    ),
                    child: attestations.when(
                      loading: /* GF-00725 — Runs an inline callback in _DeviceDetailScreenState.build. */
                          () => const LinearProgressIndicator(),
                      error: /* GF-00726 — Runs an inline callback in _DeviceDetailScreenState.build. */
                          (error, _) => ErrorCard(
                            error: error,
                            compact: true,
                            onRetry: /* GF-00727 — Runs an inline callback in _DeviceDetailScreenState.build.callback. */
                                () => ref
                                    .read(
                                      attestationsProvider(_refKey).notifier,
                                    )
                                    .reload(),
                          ),
                      data: /* GF-00728 — Runs an inline callback in _DeviceDetailScreenState.build. */
                          (records) => records.isEmpty
                          ? const AppText('MCODE-00143')
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

  /// GF-00729 — Handles refresh in _DeviceDetailScreenState.
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

  /// GF-00730 — Handles verify possession in _DeviceDetailScreenState.
  Future<void> _verifyPossession() async {
    // GF-02102 — Clear the previous action error and lock duplicate submissions.
    setState(
      /* GF-00731 — Runs an inline callback in _DeviceDetailScreenState._verifyPossession. */ () {
        _busy = true;
        _actionError = null;
      },
    );
    try {
      // GF-02103 — Run the WebAuthn assertion ownership proof.
      await ref
          .read(deviceControllerProvider)
          .provePasskeyPossession(
            projectId: widget.projectId,
            deviceId: widget.deviceId,
          );
      if (!mounted) return;
      // GF-02104 — Report verified proof and reload device evidence.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: AppText('MCODE-00443')));
      await _refresh();
    } on Object catch (error) {
      // GF-02105 — Surface proof failures in the device detail screen.
      if (mounted) {
        setState(
          /* GF-00732 — Runs an inline callback in _DeviceDetailScreenState._verifyPossession. */ () =>
              _actionError = error,
        );
      }
    } finally {
      // GF-02106 — Release the action lock after success or failure.
      if (mounted) {
        setState(
          /* GF-00733 — Runs an inline callback in _DeviceDetailScreenState._verifyPossession. */ () =>
              _busy = false,
        );
      }
    }
  }

  /// GF-00734 — Handles revoke device in _DeviceDetailScreenState.
  Future<void> _revokeDevice() async {
    // GF-02107 — Require explicit confirmation before irreversible revocation.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: /* GF-00735 — Runs an inline callback in _DeviceDetailScreenState._revokeDevice. */
          (context) => AlertDialog(
            title: const AppText('MCODE-00145'),
            content: const AppText('MCODE-00466'),
            actions: [
              TextButton(
                onPressed: /* GF-00736 — Runs an inline callback in _DeviceDetailScreenState._revokeDevice.callback. */
                    () => Navigator.pop(context, false),
                child: const AppText('MCODE-00147'),
              ),
              FilledButton(
                onPressed: /* GF-00737 — Runs an inline callback in _DeviceDetailScreenState._revokeDevice.callback. */
                    () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const AppText('MCODE-00148'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    // GF-02108 — Clear old errors and mark the revoke action as active.
    setState(
      /* GF-00738 — Runs an inline callback in _DeviceDetailScreenState._revokeDevice. */ () {
        _busy = true;
        _actionError = null;
      },
    );
    try {
      // GF-02109 — Revoke the backend record and clean up the local key.
      await ref
          .read(deviceControllerProvider)
          .revoke(projectId: widget.projectId, deviceId: widget.deviceId);
      if (!mounted) return;
      // GF-02110 — Notify the user and close the revoked device detail.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: AppText('MCODE-00149')));
      Navigator.of(context).pop();
    } on Object catch (error) {
      // GF-02111 — Keep revocation failures on the current screen.
      if (mounted) {
        setState(
          /* GF-00739 — Runs an inline callback in _DeviceDetailScreenState._revokeDevice. */ () =>
              _actionError = error,
        );
      }
    } finally {
      // GF-02112 — Release the action lock after success or failure.
      if (mounted) {
        setState(
          /* GF-00740 — Runs an inline callback in _DeviceDetailScreenState._revokeDevice. */ () =>
              _busy = false,
        );
      }
    }
  }
}
