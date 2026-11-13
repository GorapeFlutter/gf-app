import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/device.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
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
                    child: Text(
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
                    tooltip: '再読み込み',
                    onPressed: () =>
                        ref.read(devicesProvider(projectId).notifier).reload(),
                    icon: const Icon(Icons.refresh),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onRegister,
                    icon: const Icon(Icons.add),
                    label: const Text('登録'),
                  ),
                ],
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
                message:
                    'Android実機でOS保護鍵を生成し、Gorapeへ登録してください。\n'
                    '登録後、チャレンジ署名による所有証明を実行できます。',
                action: FilledButton.icon(
                  onPressed: onRegister,
                  icon: const Icon(Icons.add_moderator_outlined),
                  label: const Text('デバイスを登録'),
                ),
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
              child: Text(device.displayName, overflow: TextOverflow.ellipsis),
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
          child: Text(
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
