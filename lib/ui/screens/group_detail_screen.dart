import 'package:flutter/material.dart' hide Text;
import '../../l10n/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/providers.dart';
import '../../entity/model/group.dart';
import '../../entity/model/project.dart';
import '../../entity/model/role.dart';
import '../../entity/model/role_binding.dart';
import '../../entity/request/group.dart';
import '../widgets/common.dart';
import '../widgets/role_badge.dart';
import '../widgets/role_dialogs.dart';

/// Group-scoped entry point.
///
/// The effective group role is the stronger of the project role and the
/// Keycloak group-specific role; the matching admin/editor/viewer screen is
/// selected automatically.
class GroupScopeScreen extends ConsumerWidget {
  const GroupScopeScreen({
    super.key,
    required this.project,
    required this.group,
  });

  final Project project;
  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(roleSnapshotProvider);
    final projectRole = snapshot.projectRoleFor(project.accessKeys);
    final role = snapshot.groupRoleFor(
      group.accessKeys,
      projectRole: projectRole,
    );
    return switch (role) {
      AccessRole.admin => GroupAdminScreen(project: project, group: group),
      AccessRole.editor => GroupEditorScreen(project: project, group: group),
      AccessRole.viewer => GroupViewerScreen(project: project, group: group),
      AccessRole.none => Scaffold(
        appBar: AppBar(title: AppText(group.name)),
        body: RoleNoneScreen(scopeLabel: 'グループ「${group.name}」'),
      ),
    };
  }
}

/// Group administrator: edit/delete the group and manage group roles.
class GroupAdminScreen extends StatelessWidget {
  const GroupAdminScreen({
    super.key,
    required this.project,
    required this.group,
  });

  final Project project;
  final Group group;

  @override
  Widget build(BuildContext context) {
    return _GroupScopeView(
      project: project,
      group: group,
      role: AccessRole.admin,
    );
  }
}

/// Group editor: assign or remove devices without changing group settings.
class GroupEditorScreen extends StatelessWidget {
  const GroupEditorScreen({
    super.key,
    required this.project,
    required this.group,
  });

  final Project project;
  final Group group;

  @override
  Widget build(BuildContext context) {
    return _GroupScopeView(
      project: project,
      group: group,
      role: AccessRole.editor,
    );
  }
}

/// Group viewer: read-only group and device overview.
class GroupViewerScreen extends StatelessWidget {
  const GroupViewerScreen({
    super.key,
    required this.project,
    required this.group,
  });

  final Project project;
  final Group group;

  @override
  Widget build(BuildContext context) {
    return _GroupScopeView(
      project: project,
      group: group,
      role: AccessRole.viewer,
    );
  }
}

/// Shared group view; the per-role screens configure which operations appear.
class _GroupScopeView extends ConsumerStatefulWidget {
  const _GroupScopeView({
    required this.project,
    required this.group,
    required this.role,
  });

  final Project project;
  final Group group;
  final AccessRole role;

  @override
  ConsumerState<_GroupScopeView> createState() => _GroupScopeViewState();
}

class _GroupScopeViewState extends ConsumerState<_GroupScopeView> {
  late Group _group = widget.group;
  bool _busy = false;

  AccessRole get _role => widget.role;

  GroupRef get _refKey =>
      GroupRef(projectId: widget.project.id, groupId: _group.id);

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(groupDevicesProvider(_refKey));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: AppText(_group.name),
        actions: [
          IconButton(
            tooltip: tr(context, '再読み込み'),
            onPressed: _busy
                ? null
                : () => ref.invalidate(groupDevicesProvider(_refKey)),
            icon: Icon(Icons.refresh, size: 22),
          ),
          if (_role.canAdmin)
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    await _editGroup();
                    break;
                  case 'delete':
                    await _deleteGroup();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit, size: 22),
                    title: AppText('グループを編集'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete, size: 22),
                    title: AppText('グループを削除'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(groupDevicesProvider(_refKey));
          if (_role.canAdmin) {
            ref.invalidate(groupRoleBindingsProvider(_refKey));
          }
          await ref.read(groupDevicesProvider(_refKey).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            RoleCapabilityCard(
              role: _role,
              scopeLabel: 'グループ「${_group.name}」',
              footnote: '有効ロールはプロジェクトロールとKeycloakのグループ別ロールから解決され、API側で再認可されます。',
            ),
            if (_role == AccessRole.viewer)
              const RoleNotice(
                role: AccessRole.viewer,
                scopeLabel: '閲覧者ビュー',
                message: 'グループ情報と割り当てデバイスを参照できます。追加・削除は表示されません。',
              ),
            if (_role == AccessRole.editor)
              const RoleNotice(
                role: AccessRole.editor,
                scopeLabel: '編集者ビュー',
                message: 'グループへのデバイス追加・削除が可能です。グループ編集・削除とロール付与は管理者のみです。',
              ),
            SectionCard(
              title: 'グループ情報',
              icon: Icons.folder_shared_outlined,
              trailing: StatusChip.status(context, _group.status),
              child: Column(
                children: [
                  KeyValueRow('名前', _group.name),
                  KeyValueRow('Slug', _group.slug, monospace: true),
                  KeyValueRow('Group ID', _group.id, monospace: true),
                  KeyValueRow('作成日時', formatTimestamp(_group.createdAt)),
                  KeyValueRow('更新日時', formatTimestamp(_group.updatedAt)),
                ],
              ),
            ),
            SectionCard(
              title: 'グループデバイス',
              icon: Icons.devices_outlined,
              trailing: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (devices.hasValue)
                    StatusChip(
                      label: '${devices.value!.length} 台',
                      color: scheme.primary,
                    ),
                  if (_role.canEdit)
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : _bindDevice,
                      icon: Icon(Icons.add, size: 22),
                      label: const AppText('追加'),
                    ),
                ],
              ),
              child: devices.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => ErrorCard(
                  error: error,
                  compact: true,
                  onRetry: () => ref.invalidate(groupDevicesProvider(_refKey)),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return AppText(
                      _role.canEdit
                          ? 'デバイスが割り当てられていません。右上の「追加」から割り当てできます。'
                          : 'デバイスが割り当てられていません。',
                    );
                  }
                  return Column(
                    children: [
                      for (final device in list)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.phone_android),
                          title: AppText(device.displayName),
                          subtitle: AppText(
                            '${platformLabel(device.platform)} • '
                            '${device.status}',
                          ),
                          trailing: _role.canEdit
                              ? IconButton(
                                  tooltip: tr(context, 'グループから外す'),
                                  onPressed: _busy
                                      ? null
                                      : () => _unbindDevice(
                                          device.id,
                                          device.displayName,
                                        ),
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    color: scheme.error,
                                  ),
                                )
                              : null,
                        ),
                    ],
                  );
                },
              ),
            ),
            if (_role.canAdmin)
              SectionCard(
                title: 'グループロール',
                icon: Icons.manage_accounts_outlined,
                trailing: FilledButton.tonalIcon(
                  onPressed: _busy ? null : _assignGroupRole,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const AppText('付与'),
                ),
                child: _GroupRoleList(
                  groupRef: _refKey,
                  onDelete: _deleteGroupRole,
                ),
              ),
            Card(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security_outlined, color: scheme.outline),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppText(switch (_role) {
                        AccessRole.admin =>
                          '管理者: グループの編集・削除、デバイス割当、グループロール付与が可能です。',
                        AccessRole.editor =>
                          '編集者: グループへのデバイス追加・削除が可能です。ロール付与は管理者のみです。',
                        AccessRole.viewer => '閲覧者: グループ内のデバイスを参照できます。',
                        AccessRole.none => 'このグループのロールがありません。',
                      }, style: Theme.of(context).textTheme.bodySmall),
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

  Future<void> _editGroup() async {
    final input = await showGroupFormDialog(context, initial: _group);
    if (input == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(groupControllerProvider)
          .update(
            widget.project.id,
            _group.id,
            GroupUpdateRequest(name: input.name, status: input.status),
          );
      if (!mounted) return;
      setState(() => _group = updated);
      _showMessage('グループを更新しました。');
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText('グループを削除しますか？'),
        content: AppText('「${_group.name}」を削除します。元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const AppText('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const AppText('削除する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(groupControllerProvider)
          .delete(widget.project.id, _group.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bindDevice() async {
    final assigned = ref.read(groupDevicesProvider(_refKey)).value ?? const [];
    final all = ref.read(devicesProvider(widget.project.id)).value ?? const [];
    final assignedIds = assigned.map((device) => device.id).toSet();
    final candidates = all
        .where((device) => device.isActive && !assignedIds.contains(device.id))
        .toList(growable: false);
    if (candidates.isEmpty) {
      _showMessage('追加できるデバイスがありません。デバイスタブで登録してください。');
      return;
    }
    final deviceId = await showGroupDevicePicker(context, devices: candidates);
    if (deviceId == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(groupControllerProvider)
          .bindDevice(widget.project.id, _group.id, deviceId);
      if (mounted) _showMessage('デバイスをグループに追加しました。');
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unbindDevice(String deviceId, String name) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(groupControllerProvider)
          .unbindDevice(widget.project.id, _group.id, deviceId);
      if (mounted) _showMessage('$name をグループから外しました。');
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _assignGroupRole() async {
    final input = await showRoleBindingDialog(context, title: 'グループロールを付与');
    if (input == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(roleControllerProvider)
          .putGroupRole(
            widget.project.id,
            _group.id,
            RoleCreateRequest(
              oidcSubject: input.subject,
              role: input.role.name,
            ),
          );
      if (mounted) _showMessage('グループロールを付与しました。');
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteGroupRole(String bindingId) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(roleControllerProvider)
          .deleteGroupRole(widget.project.id, _group.id, bindingId);
      if (mounted) _showMessage('グループロールを削除しました。');
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: AppText(message)));
  }

  void _showError(Object error) {
    final friendly = friendlyError(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText('${friendly.title}: ${friendly.message}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _GroupRoleList extends ConsumerWidget {
  const _GroupRoleList({required this.groupRef, required this.onDelete});

  final GroupRef groupRef;
  final Future<void> Function(String bindingId) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bindings = ref.watch(groupRoleBindingsProvider(groupRef));
    return bindings.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => ErrorCard(
        error: error,
        compact: true,
        onRetry: () => ref.invalidate(groupRoleBindingsProvider(groupRef)),
      ),
      data: (list) {
        if (list.isEmpty) return const AppText('グループロールがありません。');
        return Column(
          children: [
            for (final GroupRoleBinding binding in list)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.person_outline),
                title: AppText(
                  binding.principalId,
                  style: const TextStyle(fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: AppText('付与 ${formatTimestamp(binding.createdAt)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RoleBadge(role: binding.accessRole),
                    IconButton(
                      tooltip: tr(context, '削除'),
                      onPressed: () => onDelete(binding.id),
                      icon: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onSurfaceVariant,
                          BlendMode.srcIn,
                        ),
                        child: Icon(Icons.delete, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
