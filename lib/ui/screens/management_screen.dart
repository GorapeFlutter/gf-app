import 'package:flutter/material.dart' hide Text;
import '../../l10n/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/providers.dart';
import '../../entity/model/project.dart';
import '../widgets/common.dart';
import 'cluster_screen.dart';
import 'group_management_screen.dart';
import 'project_management_screen.dart';

enum ManagementScope { cluster, project, groups }

/// Role-aware management area.
///
/// The scope selector switches between the Keycloak realm (cluster) overview,
/// the selected project, and the groups inside that project. Each scope renders
/// the admin/editor/viewer screen matching the role in the Keycloak token.
class ManagementScreen extends ConsumerStatefulWidget {
  /// GF-00832 — Initializes ManagementScreen.
  const ManagementScreen({super.key, required this.project});

  final Project? project;

  /// GF-00833 — Creates the state object for ManagementScreen.
  @override
  ConsumerState<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends ConsumerState<ManagementScreen> {
  ManagementScope _scope = ManagementScope.project;

  /// GF-00834 — Initializes state for _ManagementScreenState.
  @override
  void initState() {
    super.initState();
    if (widget.project == null) _scope = ManagementScope.cluster;
  }

  /// GF-00835 — Synchronizes _ManagementScreenState state after its widget changes.
  @override
  void didUpdateWidget(covariant ManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.project == null && _scope != ManagementScope.cluster) {
      _scope = ManagementScope.cluster;
    }
  }

  /// GF-00836 — Builds the widget or value for _ManagementScreenState.
  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<ManagementScope>(
            segments: [
              const ButtonSegment(
                value: ManagementScope.cluster,
                icon: Icon(Icons.public),
                label: AppText('クラスタ'),
              ),
              if (project != null) ...[
                const ButtonSegment(
                  value: ManagementScope.project,
                  icon: Icon(Icons.folder_outlined),
                  label: AppText('プロジェクト'),
                ),
                ButtonSegment(
                  value: ManagementScope.groups,
                  icon: Icon(Icons.person, size: 22),
                  label: AppText('グループ'),
                ),
              ],
            ],
            selected: {_scope},
            showSelectedIcon: false,
            onSelectionChanged: /* GF-00837 — Runs an inline callback in _ManagementScreenState.build. */
                (selection) => setState(
                  /* GF-00838 — Runs an inline callback in _ManagementScreenState.build.callback. */ () =>
                      _scope = selection.first,
                ),
          ),
        ),
        Expanded(
          child: switch (_scope) {
            ManagementScope.cluster => ClusterScopeScreen(
              onOpenProject: /* GF-00839 — Runs an inline callback in _ManagementScreenState.build. */
                  (target) => _openProject(target),
            ),
            ManagementScope.project when project != null => ProjectScopeScreen(
              project: project,
              onOpenGroups: /* GF-00840 — Runs an inline callback in _ManagementScreenState.build. */
                  () => setState(
                    /* GF-00841 — Runs an inline callback in _ManagementScreenState.build.callback. */ () =>
                        _scope = ManagementScope.groups,
                  ),
            ),
            ManagementScope.groups when project != null =>
              GroupManagementScreen(project: project),
            _ => const EmptyState(
              icon: Icons.folder_off_outlined,
              title: 'プロジェクトがありません',
              message: '管理対象のプロジェクトがありません。クラスタ表示のみ利用できます。',
            ),
          },
        ),
      ],
    );
  }

  /// GF-00842 — Handles open project in _ManagementScreenState.
  void _openProject(Project target) {
    ref.read(selectedProjectIdProvider.notifier).select(target.id);
    setState(
      /* GF-00843 — Runs an inline callback in _ManagementScreenState._openProject. */ () =>
          _scope = ManagementScope.project,
    );
  }
}
