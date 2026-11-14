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

/// Group list for the selected project, with per-group effective roles.
class GroupManagementScreen extends ConsumerStatefulWidget {
  /// GF-00808 — Initializes GroupManagementScreen.
  const GroupManagementScreen({super.key, required this.project});

  final Project project;

  /// GF-00809 — Creates the state object for GroupManagementScreen.
  @override
  ConsumerState<GroupManagementScreen> createState() =>
      _GroupManagementScreenState();
}

class _GroupManagementScreenState extends ConsumerState<GroupManagementScreen> {
  bool _busy = false;

  /// GF-00810 — Builds the widget or value for _GroupManagementScreenState.
  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(roleSnapshotProvider);
    final projectRole = snapshot.projectRoleFor(widget.project.accessKeys);
    final groups = ref.watch(groupsProvider(widget.project.id));
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: /* GF-00811 — Runs an inline callback in _GroupManagementScreenState.build. */
          () => ref.read(groupsProvider(widget.project.id).notifier).reload(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          RoleCapabilityCard(
            role: projectRole,
            scopeLabel: 'プロジェクトのグループ',
            footnote:
                '各グループのロールは、プロジェクトロールとKeycloakのグループ別ロールの'
                '強い方で表示されます（Gorapeのeffective roleと同じ考え方）。',
          ),
          SectionCard(
            title: 'グループ一覧',
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
                if (projectRole.canAdmin)
                  FilledButton.tonalIcon(
                    onPressed: _busy ? null : _createGroup,
                    icon: Icon(Icons.add, size: 22),
                    label: const AppText('作成'),
                  ),
              ],
            ),
            child: groups.when(
              loading: /* GF-00812 — Runs an inline callback in _GroupManagementScreenState.build. */
                  () => const LinearProgressIndicator(),
              error: /* GF-00813 — Runs an inline callback in _GroupManagementScreenState.build. */
                  (error, _) => ErrorCard(
                    error: error,
                    onRetry: /* GF-00814 — Runs an inline callback in _GroupManagementScreenState.build.callback. */
                        () => ref
                            .read(groupsProvider(widget.project.id).notifier)
                            .reload(),
                  ),
              data: /* GF-00815 — Runs an inline callback in _GroupManagementScreenState.build. */
                  (list) {
                    if (list.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: AppText(
                          projectRole.canAdmin
                              ? 'グループがありません。右上の「作成」から追加できます。'
                              : 'グループが作成されていません。',
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final group in list)
                          _GroupListTile(
                            project: widget.project,
                            group: group,
                            projectRole: projectRole,
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
              child: AppText(
                projectRole.canAdmin
                    ? '管理者: グループの作成・編集・削除、グループロールの付与が可能です。'
                    : projectRole.canEdit
                    ? '編集者: グループ内のデバイス割当を変更できます。グループ自体の作成・削除は管理者のみです。'
                    : '閲覧者: グループとデバイスを参照できます。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// GF-00816 — Handles create group in _GroupManagementScreenState.
  Future<void> _createGroup() async {
    // GF-02152 — Collect group details and stop when the dialog is cancelled.
    final input = await showGroupFormDialog(context);
    if (input == null || !mounted) return;
    setState(
      /* GF-00817 — Runs an inline callback in _GroupManagementScreenState._createGroup. */ () =>
          _busy = true,
    );
    try {
      // GF-02153 — Create the group and retain its server-generated record.
      final group = await ref
          .read(groupControllerProvider)
          .create(
            widget.project.id,
            GroupCreateRequest(slug: input.slug, name: input.name),
          );
      if (!mounted) return;
      // GF-02154 — Confirm creation and open the new group's detail screen.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: AppText('グループ「${input.name}」を作成しました。')));
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: /* GF-00818 — Runs an inline callback in _GroupManagementScreenState._createGroup. */
              (_) => GroupScopeScreen(project: widget.project, group: group),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      final friendly = friendlyError(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText('${friendly.title}: ${friendly.message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted)
        setState(
          /* GF-00819 — Runs an inline callback in _GroupManagementScreenState._createGroup. */ () =>
              _busy = false,
        );
    }
  }
}

class _GroupListTile extends ConsumerWidget {
  /// GF-00820 — Initializes _GroupListTile.
  const _GroupListTile({
    required this.project,
    required this.group,
    required this.projectRole,
  });

  final Project project;
  final Group group;
  final AccessRole projectRole;

  /// GF-00821 — Builds the widget or value for _GroupListTile.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(roleSnapshotProvider);
    final role = snapshot.groupRoleFor(
      group.accessKeys,
      projectRole: projectRole,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: const Icon(Icons.folder_shared_outlined),
        ),
        title: Row(
          children: [
            Flexible(
              child: AppText(group.name, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            StatusChip.status(context, group.status),
          ],
        ),
        subtitle: AppText(group.slug),
        trailing: RoleBadge(role: role),
        onTap: /* GF-00822 — Runs an inline callback in _GroupListTile.build. */
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: /* GF-00823 — Runs an inline callback in _GroupListTile.build.callback. */
                    (_) => GroupScopeScreen(project: project, group: group),
              ),
            ),
      ),
    );
  }
}
