import 'package:flutter/material.dart' hide Text;
import '../../config/langages/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../back/controller/providers.dart';
import '../../entity/model/device.dart';
import '../../entity/model/device_ref.dart';
import '../../entity/model/role.dart';
import '../widgets/common.dart';
import '../widgets/role_badge.dart';
import 'device_detail_screen.dart';

class DevicesScreen extends ConsumerWidget {
  /// GF-00741 — Initializes DevicesScreen.
  const DevicesScreen({
    super.key,
    required this.projectId,
    required this.onRegister,
  });

  final String projectId;
  final VoidCallback onRegister;

  /// GF-00742 — Builds the widget or value for DevicesScreen.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider(projectId));
    final role = ref.watch(projectRoleProvider(projectId));
    final canEdit = role.canEdit;
    final session = ref.watch(authControllerProvider).value;
    final canRegister = canEdit && (session?.isPasskeyAuthenticated ?? false);
    return RefreshIndicator(
      onRefresh: /* GF-00743 — Runs an inline callback in DevicesScreen.build. */
          () => ref.read(devicesProvider(projectId).notifier).reload(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: AppText(
                      'MCODE-00114',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (devices.hasValue)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: StatusChip(
                        label: '${devices.value!.length} 台',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  IconButton(
                    tooltip: tr(context, '再読み込み'),
                    onPressed: /* GF-00744 — Runs an inline callback in DevicesScreen.build. */
                        () => ref
                            .read(devicesProvider(projectId).notifier)
                            .reload(),
                    icon: Icon(Icons.refresh, size: 22),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: canRegister ? onRegister : null,
                    icon: Icon(Icons.add, size: 22),
                    label: const AppText('MCODE-00053'),
                  ),
                ],
              ),
            ),
          ),
          if (!canEdit)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: RoleNotice(
                  role: role,
                  scopeLabel: 'MCODE-00051',
                  message: role == AccessRole.none
                      ? 'Keycloakトークンにこのプロジェクトのロールがありません。'
                            '参照はGorape側の権限に従いますが、登録・失効などの変更操作は無効です。'
                      : '閲覧者のため、デバイスの登録・失効は実行できません。',
                ),
              ),
            ),
          if (canEdit && session?.isPasskeyAuthenticated != true)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: AppText('MCODE-00508'),
                  ),
                ),
              ),
            ),
          if (devices.isLoading && !devices.hasValue)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: LoadingView(label: 'MCODE-00043'),
            )
          else if (devices.hasError && !devices.hasValue)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ErrorCard(
                  error: devices.error!,
                  onRetry: /* GF-00745 — Runs an inline callback in DevicesScreen.build. */
                      () => ref
                          .read(devicesProvider(projectId).notifier)
                          .reload(),
                ),
              ),
            )
          else if ((devices.value ?? const []).isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.devices_other_outlined,
                title: 'MCODE-00120',
                message: !canEdit
                    ? 'MCODE-00498'
                    : canRegister
                    ? 'MCODE-00494'
                    : 'MCODE-00508',
                action: canRegister
                    ? FilledButton.icon(
                        onPressed: onRegister,
                        icon: Icon(Icons.add, size: 22),
                        label: const AppText('MCODE-00404'),
                      )
                    : null,
              ),
            )
          else
            SliverList.separated(
              itemCount: devices.value!.length,
              separatorBuilder: /* GF-00746 — Runs an inline callback in DevicesScreen.build. */
                  (_, _) => const SizedBox(height: 8),
              itemBuilder: /* GF-00747 — Runs an inline callback in DevicesScreen.build. */
                  (context, index) {
                    final device = devices.value![index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _DeviceTile(projectId: projectId, device: device),
                    );
                  },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _DeviceTile extends ConsumerWidget {
  /// GF-00748 — Initializes _DeviceTile.
  const _DeviceTile({required this.projectId, required this.device});

  final String projectId;
  final Device device;

  /// GF-00749 — Builds the widget or value for _DeviceTile.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyRef = DeviceRef(projectId: projectId, deviceId: device.id);
    final localKey = ref.watch(localDeviceKeyProvider(keyRef));
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          child: Icon(
            _platformIcon(device.platform),
            color: scheme.onSecondaryContainer,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: AppText(
                device.displayName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            StatusChip.status(context, device.status),
            if (localKey.value != null) ...[
              const SizedBox(width: 6),
              const StatusChip(
                label: 'MCODE-00122',
                color: Colors.teal,
                icon: Icons.key,
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: AppText(
            '${platformLabel(device.platform)} • 最終検証 '
            '${formatTimestamp(device.lastVerifiedAt)}\n'
            '登録 ${formatTimestamp(device.registeredAt)}',
          ),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: /* GF-00750 — Runs an inline callback in _DeviceTile.build. */ () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: /* GF-00751 — Runs an inline callback in _DeviceTile.build.callback. */
                  (_) => DeviceDetailScreen(
                    projectId: projectId,
                    deviceId: device.id,
                    initialDevice: device,
                  ),
            ),
          );
        },
      ),
    );
  }

  /// GF-00752 — Handles platform icon in _DeviceTile.
  IconData _platformIcon(String platform) {
    return switch (platform) {
      'android' => Icons.android,
      'ios' => Icons.phone_iphone,
      'macos' => Icons.laptop_mac,
      'windows' => Icons.desktop_windows_outlined,
      _ => Icons.devices_other,
    };
  }
}
