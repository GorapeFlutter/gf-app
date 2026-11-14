import 'package:flutter/material.dart' hide Text;
import '../../l10n/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/providers.dart';
import '../../entity/model/project.dart';
import '../../entity/model/role.dart';
import '../widgets/common.dart';
import '../widgets/role_badge.dart';

/// Keycloak realm-wide ("cluster") entry point.
///
/// The concrete screen is chosen from the role resolved from the Keycloak
/// token, so realm/client role changes switch the UI without code changes.
class ClusterScopeScreen extends ConsumerWidget {
  /// GF-00698 — Initializes ClusterScopeScreen.
  const ClusterScopeScreen({super.key, this.onOpenProject});

  final ValueChanged<Project>? onOpenProject;

  /// GF-00699 — Builds the widget or value for ClusterScopeScreen.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(clusterRoleProvider);
    return switch (role) {
      AccessRole.admin => ClusterAdminScreen(onOpenProject: onOpenProject),
      AccessRole.editor => ClusterEditorScreen(onOpenProject: onOpenProject),
      AccessRole.viewer => ClusterViewerScreen(onOpenProject: onOpenProject),
      AccessRole.none => const RoleNoneScreen(scopeLabel: 'クラスタ'),
    };
  }
}

/// Realm administrator: sees identity, claims, and cluster-wide role data.
class ClusterAdminScreen extends StatelessWidget {
  /// GF-00700 — Initializes ClusterAdminScreen.
  const ClusterAdminScreen({super.key, this.onOpenProject});

  final ValueChanged<Project>? onOpenProject;

  /// GF-00701 — Builds the widget or value for ClusterAdminScreen.
  @override
  Widget build(BuildContext context) {
    return _ClusterOverview(
      role: AccessRole.admin,
      onOpenProject: onOpenProject,
      showClaimDiagnostics: true,
      showAdminGuide: true,
    );
  }
}

/// Realm editor: operational overview without cluster administration tools.
class ClusterEditorScreen extends StatelessWidget {
  /// GF-00702 — Initializes ClusterEditorScreen.
  const ClusterEditorScreen({super.key, this.onOpenProject});

  final ValueChanged<Project>? onOpenProject;

  /// GF-00703 — Builds the widget or value for ClusterEditorScreen.
  @override
  Widget build(BuildContext context) {
    return _ClusterOverview(
      role: AccessRole.editor,
      onOpenProject: onOpenProject,
      showClaimDiagnostics: true,
      showAdminGuide: false,
    );
  }
}

/// Realm viewer: read-only overview of the signed-in identity and claims.
class ClusterViewerScreen extends StatelessWidget {
  /// GF-00704 — Initializes ClusterViewerScreen.
  const ClusterViewerScreen({super.key, this.onOpenProject});

  final ValueChanged<Project>? onOpenProject;

  /// GF-00705 — Builds the widget or value for ClusterViewerScreen.
  @override
  Widget build(BuildContext context) {
    return _ClusterOverview(
      role: AccessRole.viewer,
      onOpenProject: onOpenProject,
      showClaimDiagnostics: false,
      showAdminGuide: false,
    );
  }
}

/// Shared cluster overview; the per-role screens decide which sections and
/// guidance are visible.
///
/// Gorape exposes no cluster-wide API, so this screen summarizes the Keycloak
/// identity, realm/client roles, group memberships and the roles projected onto
/// each visible project.
class _ClusterOverview extends ConsumerWidget {
  /// GF-00706 — Initializes _ClusterOverview.
  const _ClusterOverview({
    required this.role,
    required this.onOpenProject,
    required this.showClaimDiagnostics,
    required this.showAdminGuide,
  });

  final AccessRole role;
  final ValueChanged<Project>? onOpenProject;
  final bool showClaimDiagnostics;
  final bool showAdminGuide;

  /// GF-00707 — Builds the widget or value for _ClusterOverview.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    final snapshot = ref.watch(roleSnapshotProvider);
    final projects = ref.watch(projectsProvider);
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        RoleCapabilityCard(
          role: role,
          scopeLabel: 'クラスタ（Keycloak realm）',
          footnote:
              'クラスタのロールはKeycloakのrealm/clientロールから判定しています。'
              'Gorapeの実認可はDBのproject/groupロール付与で行われます。',
        ),
        if (role == AccessRole.viewer)
          const RoleNotice(
            role: AccessRole.viewer,
            scopeLabel: '閲覧者',
            message: 'クラスタ情報は参照のみ表示されます。ロールやグループの変更は表示されません。',
          ),
        if (showAdminGuide)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: scheme.primaryContainer.withValues(alpha: 0.4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      AppText(
                        '管理者ビュー',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    'Keycloakでrealmロール admin が付与されています。'
                    'クラスタ全体のロール確認に加えて、各プロジェクトの管理画面へ移動できます。'
                    '実際の作成・変更権限はGorapeのproject/groupロール付与に従います。',
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
        SectionCard(
          title: 'サインイン情報',
          icon: Icons.badge_outlined,
          child: Column(
            children: [
              KeyValueRow('表示名', session?.displayName ?? '—'),
              KeyValueRow('ユーザー名', session?.username ?? '—'),
              KeyValueRow('メール', session?.email ?? '—'),
              KeyValueRow('Subject', session?.subject ?? '—', monospace: true),
              KeyValueRow('Issuer', session?.issuer ?? '—', monospace: true),
            ],
          ),
        ),
        SectionCard(
          title: 'Keycloakロール',
          icon: Icons.verified_outlined,
          trailing: StatusChip(
            label: '${snapshot.allRoles.length} 件',
            color: scheme.primary,
          ),
          child: snapshot.allRoles.isEmpty
              ? const AppText('realm_access/resource_accessにロールがありません。')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final name in snapshot.realmRoles)
                      _ClaimChip(
                        label: name,
                        role: AccessRole.fromName(name),
                        prefix: 'realm',
                      ),
                    for (final name in snapshot.clientRoles)
                      _ClaimChip(
                        label: name,
                        role: AccessRole.fromName(name),
                        prefix: 'client',
                      ),
                  ],
                ),
        ),
        SectionCard(
          title: 'Keycloakグループ',
          icon: Icons.groups_outlined,
          trailing: StatusChip(
            label: '${snapshot.groupPaths.length} 件',
            color: scheme.primary,
          ),
          child: snapshot.groupPaths.isEmpty
              ? const AppText(
                  'アクセストークンにgroupsクレームがありません。'
                  'KeycloakクライアントのGroup Membership mapperを有効にすると表示されます。',
                )
              : Column(
                  children: [
                    for (final path in snapshot.groupPaths)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(Icons.person, size: 22),
                        title: AppText(path),
                        trailing: _roleOrDash(
                          context,
                          snapshot.groupRoleFor([path]),
                        ),
                      ),
                  ],
                ),
        ),
        SectionCard(
          title: 'プロジェクト別ロール',
          icon: Icons.folder_copy_outlined,
          trailing: IconButton(
            tooltip: tr(context, '再読み込み'),
            onPressed: /* GF-00708 — Runs an inline callback in _ClusterOverview.build. */
                () => ref.read(projectsProvider.notifier).reload(),
            icon: Icon(Icons.refresh, size: 22),
          ),
          child: projects.when(
            loading: /* GF-00709 — Runs an inline callback in _ClusterOverview.build. */
                () => const LinearProgressIndicator(),
            error: /* GF-00710 — Runs an inline callback in _ClusterOverview.build. */
                (error, _) => ErrorCard(
                  error: error,
                  compact: true,
                  onRetry: /* GF-00711 — Runs an inline callback in _ClusterOverview.build.callback. */
                      () => ref.read(projectsProvider.notifier).reload(),
                ),
            data: /* GF-00712 — Runs an inline callback in _ClusterOverview.build. */
                (list) {
                  if (list.isEmpty) {
                    return const AppText('表示可能なプロジェクトがありません。');
                  }
                  return Column(
                    children: [
                      for (final item in list)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.folder_outlined),
                          title: AppText(item.name),
                          subtitle: AppText(item.slug),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RoleBadge(
                                role: snapshot.projectRoleFor(item.accessKeys),
                              ),
                              if (onOpenProject != null)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(Icons.chevron_right),
                                ),
                            ],
                          ),
                          onTap: onOpenProject == null
                              ? null
                              : /* GF-00713 — Runs an inline callback in _ClusterOverview.build.callback. */ () =>
                                    onOpenProject!(item),
                        ),
                    ],
                  );
                },
          ),
        ),
        if (showClaimDiagnostics)
          SectionCard(
            title: 'Keycloak属性（gorape_*）',
            icon: Icons.tune_outlined,
            child: snapshot.attributes.isEmpty
                ? const AppText(
                    'gorape_*属性がトークンに含まれていません。'
                    'プロジェクト/グループ固有のロールはrealmロールへフォールバックします。',
                  )
                : Column(
                    children: [
                      for (final entry in snapshot.attributes.entries)
                        KeyValueRow(entry.key, '${entry.value}'),
                    ],
                  ),
          ),
        Card(
          color: scheme.secondaryContainer.withValues(alpha: 0.45),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        scheme.onSecondaryContainer,
                        BlendMode.srcIn,
                      ),
                      child: Icon(Icons.info, size: 22),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText(
                        showAdminGuide ? 'ロール表示の切り替え方' : 'ロールの確認方法',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppText(
                  'Keycloakでユーザーにrealmロール admin / editor / viewer を付与するか、'
                  'gorape_project_role / gorape_group_<slug>_role 属性をアクセストークンへマッピングしてください。'
                  'ロールを変えると、この画面は管理者・編集者・閲覧者のいずれかに切り替わります。'
                  '変更後は再ログイン（またはトークン更新）で反映されます。',
                  style: TextStyle(color: scheme.onSecondaryContainer),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// GF-00714 — Handles role or dash in _ClusterOverview.
  Widget _roleOrDash(BuildContext context, AccessRole role) {
    if (role == AccessRole.none) {
      return AppText(
        '—',
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      );
    }
    return RoleBadge(role: role);
  }
}

class _ClaimChip extends StatelessWidget {
  /// GF-00715 — Initializes _ClaimChip.
  const _ClaimChip({
    required this.label,
    required this.role,
    required this.prefix,
  });

  final String label;
  final AccessRole? role;
  final String prefix;

  /// GF-00716 — Builds the widget or value for _ClaimChip.
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = role == null
        ? scheme.outline
        : RoleBadge.colorOf(role!, scheme);
    return Chip(
      avatar: Icon(
        role == null ? Icons.label_outline : RoleBadge.iconOf(role!),
        size: 16,
        color: color,
      ),
      label: AppText('$prefix: $label'),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}
