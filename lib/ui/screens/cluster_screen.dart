import 'package:flutter/material.dart' hide Text;
import '../../config/langages/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../back/controller/providers.dart';
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
      AccessRole.none => const RoleNoneScreen(scopeLabel: 'MCODE-00182'),
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
          scopeLabel: 'MCODE-00187',
          footnote: 'MCODE-00486',
        ),
        if (role == AccessRole.viewer)
          const RoleNotice(
            role: AccessRole.viewer,
            scopeLabel: 'MCODE-00024',
            message: 'MCODE-00189',
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
                        'MCODE-00190',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    'MCODE-00318'
                    'MCODE-00414'
                    'MCODE-00373',
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
        SectionCard(
          title: 'MCODE-00192',
          icon: Icons.badge_outlined,
          child: Column(
            children: [
              KeyValueRow('MCODE-00103', session?.displayName ?? '—'),
              KeyValueRow('MCODE-00193', session?.username ?? '—'),
              KeyValueRow('MCODE-00194', session?.email ?? '—'),
              KeyValueRow('Subject', session?.subject ?? '—', monospace: true),
              KeyValueRow('Issuer', session?.issuer ?? '—', monospace: true),
            ],
          ),
        ),
        SectionCard(
          title: 'MCODE-00195',
          icon: Icons.verified_outlined,
          trailing: StatusChip(
            label: '${snapshot.allRoles.length} 件',
            color: scheme.primary,
          ),
          child: snapshot.allRoles.isEmpty
              ? const AppText('MCODE-00196')
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
          title: 'MCODE-00197',
          icon: Icons.groups_outlined,
          trailing: StatusChip(
            label: '${snapshot.groupPaths.length} 件',
            color: scheme.primary,
          ),
          child: snapshot.groupPaths.isEmpty
              ? const AppText(
                  'MCODE-00198'
                  'MCODE-00323',
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
          title: 'MCODE-00199',
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
                    return const AppText('MCODE-00200');
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
            title: 'MCODE-00201',
            icon: Icons.tune_outlined,
            child: snapshot.attributes.isEmpty
                ? const AppText(
                    'MCODE-00341'
                    'MCODE-00360',
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
                        showAdminGuide ? 'MCODE-00202' : 'MCODE-00203',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppText(
                  'MCODE-00320'
                  'MCODE-00343'
                  'MCODE-00367'
                  'MCODE-00409',
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
      label: AppText(
        'MCODE-00499',
        parameters: {'prefix': prefix, 'label': label},
      ),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}
