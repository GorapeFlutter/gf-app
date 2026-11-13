import 'package:flutter/material.dart' hide Text;
import '../../l10n/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/providers.dart';
import '../../entity/model/device.dart';
import '../../entity/model/device_ref.dart';
import '../../entity/model/role.dart';
import '../widgets/common.dart';
import '../widgets/role_badge.dart';
import 'device_detail_screen.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({
    super.key,
    required this.projectId,
    required this.onRegister,
  });

  final String projectId;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider(projectId));
    final role = ref.watch(projectRoleProvider(projectId));
    final canEdit = role.canEdit;
    return RefreshIndicator(
      onRefresh: () => ref.read(devicesProvider(projectId).notifier).reload(),
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
                      '登録済みデバイス',
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
                    onPressed: () =>
                        ref.read(devicesProvider(projectId).notifier).reload(),
                    icon: Icon(Icons.refresh, size: 22),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: canEdit ? onRegister : null,
                    icon: Icon(Icons.add, size: 22),
                    label: const AppText('登録'),
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
                  scopeLabel: 'デバイス',
                  message: role == AccessRole.none
                      ? 'Keycloakトークンにこのプロジェクトのロールがありません。'
                            '参照はGorape側の権限に従いますが、登録・失効などの変更操作は無効です。'
                      : '閲覧者のため、デバイスの登録・失効は実行できません。',
                ),
              ),
            ),
          if (devices.isLoading && !devices.hasValue)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: LoadingView(label: 'デバイスを読み込み中...'),
            )
          else if (devices.hasError && !devices.hasValue)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ErrorCard(
                  error: devices.error!,
                  onRetry: () =>
                      ref.read(devicesProvider(projectId).notifier).reload(),
                ),
              ),
            )
          else if ((devices.value ?? const []).isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.devices_other_outlined,
                title: 'デバイスが登録されていません',
                message: canEdit
                    ? 'Android実機でOS保護鍵を生成し、Gorapeへ登録してください。\n'
                          '登録後、チャレンジ署名による所有証明を実行できます。'
                    : 'このスコープではデバイスを登録できません。'
                          '管理者または編集者のロールが必要です。',
                action: canEdit
                    ? FilledButton.icon(
                        onPressed: onRegister,
                        icon: Icon(Icons.add, size: 22),
                        label: const AppText('デバイスを登録'),
                      )
                    : null,
              ),
            )
          else
            SliverList.separated(
              itemCount: devices.value!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
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
  const _DeviceTile({required this.projectId, required this.device});

  final String projectId;
  final Device device;

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
                label: 'この端末の鍵',
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
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DeviceDetailScreen(
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
