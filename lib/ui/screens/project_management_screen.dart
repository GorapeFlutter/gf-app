import 'package:flutter/material.dart' hide Text;
import '../../l10n/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/providers.dart';
import '../../entity/model/group.dart';
import '../../entity/model/project.dart';
import '../../entity/model/role.dart';
import '../../entity/request/group.dart';
import '../widgets/common.dart';
import '../widgets/role_badge.dart';
import '../widgets/role_dialogs.dart';
import 'group_detail_screen.dart';

/// Project-scoped entry point.
///
/// The concrete admin/editor/viewer screen is selected from the role resolved
/// from Keycloak claims. The role only gates the UI; Gorape still authorizes
/// every API call against its own role bindings.
class ProjectScopeScreen extends ConsumerWidget {
  /// GF-00855 — Initializes ProjectScopeScreen.
  const ProjectScopeScreen({
    super.key,
    required this.project,
    this.onOpenGroups,
  });

  final Project project;
  final VoidCallback? onOpenGroups;

  /// GF-00856 — Builds the widget or value for ProjectScopeScreen.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref
        .watch(roleSnapshotProvider)
        .projectRoleFor(project.accessKeys);
    return switch (role) {
      AccessRole.admin => ProjectAdminScreen(
        project: project,
        onOpenGroups: onOpenGroups,
      ),
      AccessRole.editor => ProjectEditorScreen(
        project: project,
        onOpenGroups: onOpenGroups,
      ),
      AccessRole.viewer => ProjectViewerScreen(
        project: project,
        onOpenGroups: onOpenGroups,
      ),
      AccessRole.none => RoleNoneScreen(scopeLabel: 'プロジェクト「${project.name}」'),
    };
  }
}

/// Project administrator: group management and role binding management.
class ProjectAdminScreen extends StatelessWidget {
  /// GF-00857 — Initializes ProjectAdminScreen.
  const ProjectAdminScreen({
    super.key,
    required this.project,
    this.onOpenGroups,
  });

  final Project project;
  final VoidCallback? onOpenGroups;

  /// GF-00858 — Builds the widget or value for ProjectAdminScreen.
  @override
  Widget build(BuildContext context) {
    return _ProjectScopeView(
      project: project,
      role: AccessRole.admin,
      onOpenGroups: onOpenGroups,
    );
  }
}

/// Project editor: device operations and group device assignment.
class ProjectEditorScreen extends StatelessWidget {
  /// GF-00859 — Initializes ProjectEditorScreen.
  const ProjectEditorScreen({
    super.key,
    required this.project,
    this.onOpenGroups,
  });

  final Project project;
  final VoidCallback? onOpenGroups;

  /// GF-00860 — Builds the widget or value for ProjectEditorScreen.
  @override
  Widget build(BuildContext context) {
    return _ProjectScopeView(
      project: project,
      role: AccessRole.editor,
      onOpenGroups: onOpenGroups,
    );
  }
}

/// Project viewer: read-only project, group and device overview.
class ProjectViewerScreen extends StatelessWidget {
  /// GF-00861 — Initializes ProjectViewerScreen.
  const ProjectViewerScreen({
    super.key,
    required this.project,
    this.onOpenGroups,
  });

  final Project project;
  final VoidCallback? onOpenGroups;

  /// GF-00862 — Builds the widget or value for ProjectViewerScreen.
  @override
  Widget build(BuildContext context) {
    return _ProjectScopeView(
      project: project,
      role: AccessRole.viewer,
      onOpenGroups: onOpenGroups,
    );
  }
}

/// Shared project view; the per-role screens configure which operations are
/// exposed.
class _ProjectScopeView extends ConsumerStatefulWidget {
  /// GF-00863 — Initializes _ProjectScopeView.
  const _ProjectScopeView({
    required this.project,
    required this.role,
    this.onOpenGroups,
  });

  final Project project;
  final AccessRole role;
  final VoidCallback? onOpenGroups;

  /// GF-00864 — Creates the state object for _ProjectScopeView.
  @override
  ConsumerState<_ProjectScopeView> createState() => _ProjectScopeViewState();
}

class _ProjectScopeViewState extends ConsumerState<_ProjectScopeView> {
  bool _busy = false;

  /// GF-00865 — Builds the widget or value for _ProjectScopeViewState.
  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    final groups = ref.watch(groupsProvider(widget.project.id));
    final devices = ref.watch(devicesProvider(widget.project.id));
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        RoleCapabilityCard(
          role: role,
          scopeLabel: 'プロジェクト「${widget.project.name}」',
          footnote:
              '表示はKeycloakトークンのロールを反映し、API認可はGorape側でDBロール付与とKeycloakロールを用いて判定されます。',
        ),
        if (role == AccessRole.viewer)
          const RoleNotice(
            role: AccessRole.viewer,
            scopeLabel: '閲覧者ビュー',
            message: 'プロジェクト、グループ、デバイスを参照できます。作成・変更・失効の操作は表示されません。',
          ),
        if (role == AccessRole.editor)
          const RoleNotice(
            role: AccessRole.editor,
            scopeLabel: '編集者ビュー',
            message:
                'デバイスの失効とグループへのデバイス割当が可能です。'
                'グループの作成・削除やロール付与は管理者のみ表示されます。',
          ),
        SectionCard(
          title: 'プロジェクト情報',
          icon: Icons.folder_outlined,
          trailing: StatusChip.status(context, widget.project.status),
          child: Column(
            children: [
              KeyValueRow('名前', widget.project.name),
              KeyValueRow('Slug', widget.project.slug, monospace: true),
              KeyValueRow('Project ID', widget.project.id, monospace: true),
              KeyValueRow(
                'Keycloak Realm',
                widget.project.keycloakRealm.isEmpty
                    ? '—'
                    : widget.project.keycloakRealm,
              ),
              KeyValueRow('OIDC Issuer', widget.project.oidcIssuer),
            ],
          ),
        ),
        SectionCard(
          title: 'グループ',
          icon: Icons.groups_outlined,
          trailing: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (groups.hasValue)
                StatusChip(
                  label: '${groups.value!.length} 件',
                  color: scheme.primary,
                ),
              if (role.canAdmin)
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _createGroup,
                  icon: Icon(Icons.add, size: 22),
                  label: const AppText('作成'),
                ),
            ],
          ),
          child: groups.when(
            loading: /* GF-00866 — Runs an inline callback in _ProjectScopeViewState.build. */
                () => const LinearProgressIndicator(),
            error: /* GF-00867 — Runs an inline callback in _ProjectScopeViewState.build. */
                (error, _) => ErrorCard(
                  error: error,
                  compact: true,
                  onRetry: /* GF-00868 — Runs an inline callback in _ProjectScopeViewState.build.callback. */
                      () => ref
                          .read(groupsProvider(widget.project.id).notifier)
                          .reload(),
                ),
            data: /* GF-00869 — Runs an inline callback in _ProjectScopeViewState.build. */
                (list) => _GroupList(
                  project: widget.project,
                  groups: list,
                  onOpenGroups: widget.onOpenGroups,
                ),
          ),
        ),
        if (role.canAdmin)
          SectionCard(
            title: 'プロジェクトロール',
            icon: Icons.manage_accounts_outlined,
            trailing: FilledButton.tonalIcon(
              onPressed: _busy ? null : _assignProjectRole,
              icon: const Icon(Icons.person_add_alt_1),
              label: const AppText('付与'),
            ),
            child: _ProjectRoleList(
              project: widget.project,
              onDelete: _deleteProjectRole,
            ),
          ),
        SectionCard(
          title: 'デバイス',
          icon: Icons.devices_outlined,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (devices.hasValue)
                StatusChip(
                  label: '${devices.value!.length} 台',
                  color: scheme.primary,
                ),
              IconButton(
                tooltip: tr(context, '再読み込み'),
                onPressed: /* GF-00870 — Runs an inline callback in _ProjectScopeViewState.build. */
                    () => ref
                        .read(devicesProvider(widget.project.id).notifier)
                        .reload(),
                icon: Icon(Icons.refresh, size: 22),
              ),
            ],
          ),
          child: devices.when(
            loading: /* GF-00871 — Runs an inline callback in _ProjectScopeViewState.build. */
                () => const LinearProgressIndicator(),
            error: /* GF-00872 — Runs an inline callback in _ProjectScopeViewState.build. */
                (error, _) => ErrorCard(
                  error: error,
                  compact: true,
                  onRetry: /* GF-00873 — Runs an inline callback in _ProjectScopeViewState.build.callback. */
                      () => ref
                          .read(devicesProvider(widget.project.id).notifier)
                          .reload(),
                ),
            data: /* GF-00874 — Runs an inline callback in _ProjectScopeViewState.build. */
                (list) {
                  if (list.isEmpty) return const AppText('デバイスが登録されていません。');
                  final shown = list.take(6).toList(growable: false);
                  return Column(
                    children: [
                      for (final device in shown)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.phone_android),
                          title: AppText(device.displayName),
                          subtitle: AppText(
                            '${platformLabel(device.platform)} • '
                            '${device.status}',
                          ),
                          trailing: role.canEdit && device.isActive
                              ? IconButton(
                                  tooltip: tr(context, '失効'),
                                  onPressed: _busy
                                      ? null
                                      : /* GF-00875 — Runs an inline callback in _ProjectScopeViewState.build.callback. */ () =>
                                            _revokeDevice(
                                              device.id,
                                              device.displayName,
                                            ),
                                  icon: Icon(Icons.block, color: scheme.error),
                                )
                              : null,
                        ),
                      if (list.length > shown.length)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AppText(
                            'ほか ${list.length - shown.length} 台（デバイスタブで確認）',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  );
                },
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
                  child: AppText(switch (role) {
                    AccessRole.admin =>
                      '管理者: グループ作成・プロジェクト/グループのロール付与・デバイス失効が可能です。',
                    AccessRole.editor =>
                      '編集者: デバイス失効とグループへのデバイス割当が可能です。'
                          'グループ作成とロール付与は管理者のみです。',
                    AccessRole.viewer => '閲覧者: 参照のみ可能です。変更操作は表示されません。',
                    AccessRole.none => 'このスコープのロールがありません。',
                  }, style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// GF-00876 — Handles create group in _ProjectScopeViewState.
  Future<void> _createGroup() async {
    // GF-02144 — Collect group details and stop when the dialog is cancelled.
    final input = await showGroupFormDialog(context);
    if (input == null || !mounted) return;
    setState(
      /* GF-00877 — Runs an inline callback in _ProjectScopeViewState._createGroup. */ () =>
          _busy = true,
    );
    try {
      // GF-02145 — Create the group and show the outcome in project management.
      await ref
          .read(groupControllerProvider)
          .create(
            widget.project.id,
            GroupCreateRequest(slug: input.slug, name: input.name),
          );
      if (mounted) {
        _showMessage('グループ「${input.name}」を作成しました。');
      }
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted)
        setState(
          /* GF-00878 — Runs an inline callback in _ProjectScopeViewState._createGroup. */ () =>
              _busy = false,
        );
    }
  }

  /// GF-00879 — Handles assign project role in _ProjectScopeViewState.
  Future<void> _assignProjectRole() async {
    // GF-02146 — Collect the subject and role to grant.
    final input = await showRoleBindingDialog(context);
    if (input == null || !mounted) return;
    setState(
      /* GF-00880 — Runs an inline callback in _ProjectScopeViewState._assignProjectRole. */ () =>
          _busy = true,
    );
    try {
      // GF-02147 — Persist the project role binding through the role controller.
      await ref
          .read(roleControllerProvider)
          .putProjectRole(
            widget.project.id,
            RoleCreateRequest(
              oidcSubject: input.subject,
              role: input.role.name,
            ),
          );
      if (mounted) _showMessage('プロジェクトロールを付与しました。');
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted)
        setState(
          /* GF-00881 — Runs an inline callback in _ProjectScopeViewState._assignProjectRole. */ () =>
              _busy = false,
        );
    }
  }

  /// GF-00882 — Handles delete project role in _ProjectScopeViewState.
  Future<void> _deleteProjectRole(String bindingId) async {
    // GF-02148 — Mark the role-binding change as active.
    setState(
      /* GF-00883 — Runs an inline callback in _ProjectScopeViewState._deleteProjectRole. */ () =>
          _busy = true,
    );
    try {
      // GF-02149 — Delete the selected project role binding in Gorape.
      await ref
          .read(roleControllerProvider)
          .deleteProjectRole(widget.project.id, bindingId);
      if (mounted) _showMessage('プロジェクトロールを削除しました。');
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted)
        setState(
          /* GF-00884 — Runs an inline callback in _ProjectScopeViewState._deleteProjectRole. */ () =>
              _busy = false,
        );
    }
  }

  /// GF-00885 — Handles revoke device in _ProjectScopeViewState.
  Future<void> _revokeDevice(String deviceId, String name) async {
    // GF-02150 — Confirm the irreversible device revocation.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: /* GF-00886 — Runs an inline callback in _ProjectScopeViewState._revokeDevice. */
          (context) => AlertDialog(
            title: const AppText('デバイスを失効しますか？'),
            content: AppText('$name をGorape側でrevokedにします。元に戻せません。'),
            actions: [
              TextButton(
                onPressed: /* GF-00887 — Runs an inline callback in _ProjectScopeViewState._revokeDevice.callback. */
                    () => Navigator.of(context).pop(false),
                child: const AppText('キャンセル'),
              ),
              FilledButton(
                onPressed: /* GF-00888 — Runs an inline callback in _ProjectScopeViewState._revokeDevice.callback. */
                    () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const AppText('失効する'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    setState(
      /* GF-00889 — Runs an inline callback in _ProjectScopeViewState._revokeDevice. */ () =>
          _busy = true,
    );
    try {
      // GF-02151 — Revoke the device and clean up any local key record.
      await ref
          .read(deviceControllerProvider)
          .revoke(projectId: widget.project.id, deviceId: deviceId);
      if (mounted) _showMessage('デバイスを失効しました。');
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted)
        setState(
          /* GF-00890 — Runs an inline callback in _ProjectScopeViewState._revokeDevice. */ () =>
              _busy = false,
        );
    }
  }

  /// GF-00891 — Handles show message in _ProjectScopeViewState.
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: AppText(message)));
  }

  /// GF-00892 — Handles show error in _ProjectScopeViewState.
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

class _GroupList extends StatelessWidget {
  /// GF-00893 — Initializes _GroupList.
  const _GroupList({
    required this.project,
    required this.groups,
    this.onOpenGroups,
  });

  final Project project;
  final List<Group> groups;
  final VoidCallback? onOpenGroups;

  /// GF-00894 — Builds the widget or value for _GroupList.
  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const AppText('グループが作成されていません。');
    }
    final shown = groups.take(6).toList(growable: false);
    return Column(
      children: [
        for (final group in shown) _GroupTile(project: project, group: group),
        if (groups.length > shown.length && onOpenGroups != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpenGroups,
              icon: Icon(Icons.person, size: 22),
              label: AppText('すべて表示（${groups.length} 件）'),
            ),
          ),
      ],
    );
  }
}

class _GroupTile extends ConsumerWidget {
  /// GF-00895 — Initializes _GroupTile.
  const _GroupTile({required this.project, required this.group});

  final Project project;
  final Group group;

  /// GF-00896 — Builds the widget or value for _GroupTile.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(roleSnapshotProvider);
    final projectRole = snapshot.projectRoleFor(project.accessKeys);
    final groupRole = snapshot.groupRoleFor(
      group.accessKeys,
      projectRole: projectRole,
    );
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.folder_shared_outlined),
      title: AppText(group.name),
      subtitle: AppText(group.slug),
      trailing: RoleBadge(role: groupRole),
      onTap: /* GF-00897 — Runs an inline callback in _GroupTile.build. */ () =>
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: /* GF-00898 — Runs an inline callback in _GroupTile.build.callback. */
                  (_) => GroupScopeScreen(project: project, group: group),
            ),
          ),
    );
  }
}

class _ProjectRoleList extends ConsumerWidget {
  /// GF-00899 — Initializes _ProjectRoleList.
  const _ProjectRoleList({required this.project, required this.onDelete});

  final Project project;
  final Future<void> Function(String bindingId) onDelete;

  /// GF-00900 — Builds the widget or value for _ProjectRoleList.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bindings = ref.watch(projectRoleBindingsProvider(project.id));
    return bindings.when(
      loading: /* GF-00901 — Runs an inline callback in _ProjectRoleList.build. */
          () => const LinearProgressIndicator(),
      error: /* GF-00902 — Runs an inline callback in _ProjectRoleList.build. */
          (error, _) => ErrorCard(
            error: error,
            compact: true,
            onRetry: /* GF-00903 — Runs an inline callback in _ProjectRoleList.build.callback. */
                () => ref.invalidate(projectRoleBindingsProvider(project.id)),
          ),
      data: /* GF-00904 — Runs an inline callback in _ProjectRoleList.build. */
          (list) {
            if (list.isEmpty) return const AppText('プロジェクトロールがありません。');
            return Column(
              children: [
                for (final binding in list)
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
                          tooltip: tr(context, '削除'),
                          onPressed: /* GF-00905 — Runs an inline callback in _ProjectRoleList.build.callback. */
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
