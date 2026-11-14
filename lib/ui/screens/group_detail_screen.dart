import 'package:flutter/material.dart' hide Text;
import '../../config/langages/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../back/controller/providers.dart';
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
  /// GF-00753 — Initializes GroupScopeScreen.
  const GroupScopeScreen({
    super.key,
    required this.project,
    required this.group,
  });

  final Project project;
  final Group group;

  /// GF-00754 — Builds the widget or value for GroupScopeScreen.
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
  /// GF-00755 — Initializes GroupAdminScreen.
  const GroupAdminScreen({
    super.key,
    required this.project,
    required this.group,
  });

  final Project project;
  final Group group;

  /// GF-00756 — Builds the widget or value for GroupAdminScreen.
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
  /// GF-00757 — Initializes GroupEditorScreen.
  const GroupEditorScreen({
    super.key,
    required this.project,
    required this.group,
  });

  final Project project;
  final Group group;

  /// GF-00758 — Builds the widget or value for GroupEditorScreen.
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
  /// GF-00759 — Initializes GroupViewerScreen.
  const GroupViewerScreen({
    super.key,
    required this.project,
    required this.group,
  });

  final Project project;
  final Group group;

  /// GF-00760 — Builds the widget or value for GroupViewerScreen.
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
  /// GF-00761 — Initializes _GroupScopeView.
  const _GroupScopeView({
    required this.project,
    required this.group,
    required this.role,
  });

  final Project project;
  final Group group;
  final AccessRole role;

  /// GF-00762 — Creates the state object for _GroupScopeView.
  @override
  ConsumerState<_GroupScopeView> createState() => _GroupScopeViewState();
}

class _GroupScopeViewState extends ConsumerState<_GroupScopeView> {
  late Group _group = widget.group;
  bool _busy = false;

  /// GF-00763 — Computes _GroupScopeViewState._role.
  AccessRole get _role => widget.role;

  /// GF-00764 — Computes _GroupScopeViewState._refKey.
  GroupRef get _refKey =>
      GroupRef(projectId: widget.project.id, groupId: _group.id);

  /// GF-00765 — Builds the widget or value for _GroupScopeViewState.
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
                : /* GF-00766 — Runs an inline callback in _GroupScopeViewState.build. */ () =>
                      ref.invalidate(groupDevicesProvider(_refKey)),
            icon: Icon(Icons.refresh, size: 22),
          ),
          if (_role.canAdmin)
            PopupMenuButton<String>(
              onSelected: /* GF-00767 — Runs an inline callback in _GroupScopeViewState.build. */
                  (value) async {
                    switch (value) {
                      case 'edit':
                        await _editGroup();
                        break;
                      case 'delete':
                        await _deleteGroup();
                        break;
                    }
                  },
              itemBuilder: /* GF-00768 — Runs an inline callback in _GroupScopeViewState.build. */
                  (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit, size: 22),
                        title: AppText('MCODE-00233'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete, size: 22),
                        title: AppText('MCODE-00234'),
                      ),
                    ),
                  ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: /* GF-00769 — Runs an inline callback in _GroupScopeViewState.build. */
            () async {
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
                scopeLabel: 'MCODE-00261',
                message: 'MCODE-00401',
              ),
            if (_role == AccessRole.editor)
              const RoleNotice(
                role: AccessRole.editor,
                scopeLabel: 'MCODE-00213',
                message: 'MCODE-00399',
              ),
            SectionCard(
              title: 'MCODE-00225',
              icon: Icons.folder_shared_outlined,
              trailing: StatusChip.status(context, _group.status),
              child: Column(
                children: [
                  KeyValueRow('MCODE-00215', _group.name),
                  KeyValueRow('MCODE-00268', _group.slug, monospace: true),
                  KeyValueRow('Group ID', _group.id, monospace: true),
                  KeyValueRow('MCODE-00226', formatTimestamp(_group.createdAt)),
                  KeyValueRow('MCODE-00227', formatTimestamp(_group.updatedAt)),
                ],
              ),
            ),
            SectionCard(
              title: 'MCODE-00228',
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
                      label: const AppText('MCODE-00229'),
                    ),
                ],
              ),
              child: devices.when(
                loading: /* GF-00770 — Runs an inline callback in _GroupScopeViewState.build. */
                    () => const LinearProgressIndicator(),
                error: /* GF-00771 — Runs an inline callback in _GroupScopeViewState.build. */
                    (error, _) => ErrorCard(
                      error: error,
                      compact: true,
                      onRetry: /* GF-00772 — Runs an inline callback in _GroupScopeViewState.build.callback. */
                          () => ref.invalidate(groupDevicesProvider(_refKey)),
                    ),
                data: /* GF-00773 — Runs an inline callback in _GroupScopeViewState.build. */
                    (list) {
                      if (list.isEmpty) {
                        return AppText(
                          _role.canEdit ? 'MCODE-00231' : 'MCODE-00230',
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
                                          : /* GF-00774 — Runs an inline callback in _GroupScopeViewState.build.callback. */ () =>
                                                _unbindDevice(
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
                title: 'MCODE-00217',
                icon: Icons.manage_accounts_outlined,
                trailing: FilledButton.tonalIcon(
                  onPressed: _busy ? null : _assignGroupRole,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const AppText('MCODE-00219'),
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
                        AccessRole.admin => 'MCODE-00262',
                        AccessRole.editor => 'MCODE-00263',
                        AccessRole.viewer => 'MCODE-00264',
                        AccessRole.none => 'MCODE-00224',
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

  /// GF-00775 — Handles edit group in _GroupScopeViewState.
  Future<void> _editGroup() async {
    // GF-02129 — Collect group edits and stop when the dialog is cancelled.
    final input = await showGroupFormDialog(context, initial: _group);
    if (input == null || !mounted) return;
    setState(
      /* GF-00776 — Runs an inline callback in _GroupScopeViewState._editGroup. */ () =>
          _busy = true,
    );
    try {
      // GF-02130 — Persist the group changes through the group controller.
      final updated = await ref
          .read(groupControllerProvider)
          .update(
            widget.project.id,
            _group.id,
            GroupUpdateRequest(name: input.name, status: input.status),
          );
      if (!mounted) return;
      // GF-02131 — Replace local group state and report the successful update.
      setState(
        /* GF-00777 — Runs an inline callback in _GroupScopeViewState._editGroup. */ () =>
            _group = updated,
      );
      _showMessage('グループを更新しました。');
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted)
        setState(
          /* GF-00778 — Runs an inline callback in _GroupScopeViewState._editGroup. */ () =>
              _busy = false,
        );
    }
  }

  /// GF-00779 — Handles delete group in _GroupScopeViewState.
  Future<void> _deleteGroup() async {
    // GF-02132 — Confirm the irreversible group deletion with the user.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: /* GF-00780 — Runs an inline callback in _GroupScopeViewState._deleteGroup. */
          (context) => AlertDialog(
            title: const AppText('MCODE-00235'),
            content: AppText('MCODE-00433', parameters: {'name': _group.name}),
            actions: [
              TextButton(
                onPressed: /* GF-00781 — Runs an inline callback in _GroupScopeViewState._deleteGroup.callback. */
                    () => Navigator.of(context).pop(false),
                child: const AppText('MCODE-00147'),
              ),
              FilledButton(
                onPressed: /* GF-00782 — Runs an inline callback in _GroupScopeViewState._deleteGroup.callback. */
                    () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const AppText('MCODE-00240'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    setState(
      /* GF-00783 — Runs an inline callback in _GroupScopeViewState._deleteGroup. */ () =>
          _busy = true,
    );
    try {
      // GF-02133 — Delete the group through the group controller.
      await ref
          .read(groupControllerProvider)
          .delete(widget.project.id, _group.id);
      if (!mounted) return;
      // GF-02134 — Close the detail view after successful deletion.
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted)
        setState(
          /* GF-00784 — Runs an inline callback in _GroupScopeViewState._deleteGroup. */ () =>
              _busy = false,
        );
    }
  }

  /// GF-00785 — Handles bind device in _GroupScopeViewState.
  Future<void> _bindDevice() async {
    // GF-02135 — Find active devices that are not already assigned.
    final assigned = ref.read(groupDevicesProvider(_refKey)).value ?? const [];
    final all = ref.read(devicesProvider(widget.project.id)).value ?? const [];
    final assignedIds = assigned
        .map(
          /* GF-00786 — Runs an inline callback in _GroupScopeViewState._bindDevice. */ (
            device,
          ) => device.id,
        )
        .toSet();
    final candidates = all
        .where(
          /* GF-00787 — Runs an inline callback in _GroupScopeViewState._bindDevice. */ (
            device,
          ) => device.isActive && !assignedIds.contains(device.id),
        )
        .toList(growable: false);
    if (candidates.isEmpty) {
      _showMessage('追加できるデバイスがありません。デバイスタブで登録してください。');
      return;
    }
    // GF-02136 — Ask the user to choose one eligible device.
    final deviceId = await showGroupDevicePicker(context, devices: candidates);
    if (deviceId == null || !mounted) return;
    setState(
      /* GF-00788 — Runs an inline callback in _GroupScopeViewState._bindDevice. */ () =>
          _busy = true,
    );
    try {
      // GF-02137 — Add the selected device to the group's backend membership.
      await ref
          .read(groupControllerProvider)
          .bindDevice(widget.project.id, _group.id, deviceId);
      if (mounted) _showMessage('デバイスをグループに追加しました。');
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted)
        setState(
          /* GF-00789 — Runs an inline callback in _GroupScopeViewState._bindDevice. */ () =>
              _busy = false,
        );
    }
  }

  /// GF-00790 — Handles unbind device in _GroupScopeViewState.
  Future<void> _unbindDevice(String deviceId, String name) async {
    // GF-02138 — Mark the group membership change as active.
    setState(
      /* GF-00791 — Runs an inline callback in _GroupScopeViewState._unbindDevice. */ () =>
          _busy = true,
    );
    try {
      // GF-02139 — Remove the device from the backend group membership.
      await ref
          .read(groupControllerProvider)
          .unbindDevice(widget.project.id, _group.id, deviceId);
      if (mounted) _showMessage('$name をグループから外しました。');
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted)
        setState(
          /* GF-00792 — Runs an inline callback in _GroupScopeViewState._unbindDevice. */ () =>
              _busy = false,
        );
    }
  }

  /// GF-00793 — Handles assign group role in _GroupScopeViewState.
  Future<void> _assignGroupRole() async {
    // GF-02140 — Collect the subject and role to grant.
    final input = await showRoleBindingDialog(context, title: 'MCODE-00242');
    if (input == null || !mounted) return;
    setState(
      /* GF-00794 — Runs an inline callback in _GroupScopeViewState._assignGroupRole. */ () =>
          _busy = true,
    );
    try {
      // GF-02141 — Persist the group role binding through the role controller.
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
      if (mounted)
        setState(
          /* GF-00795 — Runs an inline callback in _GroupScopeViewState._assignGroupRole. */ () =>
              _busy = false,
        );
    }
  }

  /// GF-00796 — Handles delete group role in _GroupScopeViewState.
  Future<void> _deleteGroupRole(String bindingId) async {
    // GF-02142 — Mark the role-binding change as active.
    setState(
      /* GF-00797 — Runs an inline callback in _GroupScopeViewState._deleteGroupRole. */ () =>
          _busy = true,
    );
    try {
      // GF-02143 — Delete the selected group role binding in Gorape.
      await ref
          .read(roleControllerProvider)
          .deleteGroupRole(widget.project.id, _group.id, bindingId);
      if (mounted) _showMessage('グループロールを削除しました。');
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted)
        setState(
          /* GF-00798 — Runs an inline callback in _GroupScopeViewState._deleteGroupRole. */ () =>
              _busy = false,
        );
    }
  }

  /// GF-00799 — Handles show message in _GroupScopeViewState.
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: AppText(message)));
  }

  /// GF-00800 — Handles show error in _GroupScopeViewState.
  void _showError(Object error) {
    final friendly = friendlyError(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(
          'MCODE-00500',
          parameters: {'title': friendly.title, 'message': friendly.message},
          localizedParameters: const {'title', 'message'},
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _GroupRoleList extends ConsumerWidget {
  /// GF-00801 — Initializes _GroupRoleList.
  const _GroupRoleList({required this.groupRef, required this.onDelete});

  final GroupRef groupRef;
  final Future<void> Function(String bindingId) onDelete;

  /// GF-00802 — Builds the widget or value for _GroupRoleList.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bindings = ref.watch(groupRoleBindingsProvider(groupRef));
    return bindings.when(
      loading: /* GF-00803 — Runs an inline callback in _GroupRoleList.build. */
          () => const LinearProgressIndicator(),
      error: /* GF-00804 — Runs an inline callback in _GroupRoleList.build. */
          (error, _) => ErrorCard(
            error: error,
            compact: true,
            onRetry: /* GF-00805 — Runs an inline callback in _GroupRoleList.build.callback. */
                () => ref.invalidate(groupRoleBindingsProvider(groupRef)),
          ),
      data: /* GF-00806 — Runs an inline callback in _GroupRoleList.build. */
          (list) {
            if (list.isEmpty) return const AppText('MCODE-00250');
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
                    subtitle: AppText(
                      '付与 ${formatTimestamp(binding.createdAt)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RoleBadge(role: binding.accessRole),
                        IconButton(
                          tooltip: tr(context, 'MCODE-00496'),
                          onPressed: /* GF-00807 — Runs an inline callback in _GroupRoleList.build.callback. */
                              () => onDelete(binding.id),
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
