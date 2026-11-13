import 'package:flutter/material.dart' hide Text;
import '../../l10n/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/providers.dart';
import '../../entity/model/project.dart';
import '../widgets/common.dart';
import 'devices_screen.dart';
import 'management_screen.dart';
import 'policy_screen.dart';
import 'register_device_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _titles = ['デバイス', 'デバイス登録', '対応状況', 'デバイスポリシー', '管理', '設定'];

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final project = ref.watch(selectedProjectProvider);
    final session = ref.watch(authControllerProvider).value;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
              child: Icon(Icons.security, size: 22),
            ),
            const SizedBox(width: 8),
            Flexible(child: AppText(_titles[_index])),
          ],
        ),
        actions: [
          if (project != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ActionChip(
                avatar: Icon(
                  Icons.folder_outlined,
                  size: 16,
                  color: scheme.primary,
                ),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: AppText(project.name, overflow: TextOverflow.ellipsis),
                ),
                tooltip: tr(context, 'プロジェクトを切り替え'),
                onPressed: () => _showProjectSheet(context),
              ),
            ),
          PopupMenuButton<String>(
            tooltip: tr(context, 'アカウント'),
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) async {
              switch (value) {
                case 'settings':
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                  break;
                case 'signout':
                  await ref.read(authControllerProvider.notifier).signOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: AppText(session?.displayName ?? 'Signed in'),
                  subtitle: AppText(
                    session?.email ?? session?.subject ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.settings, size: 22),
                  title: AppText('接続設定'),
                ),
              ),
              PopupMenuItem(
                value: 'signout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.history, size: 22),
                  title: AppText('ログアウト'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(projects, project),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.devices, size: 22),
            selectedIcon: Icon(Icons.devices, size: 22),
            label: tr(context, 'デバイス'),
          ),
          NavigationDestination(
            icon: Icon(Icons.add, size: 22),
            selectedIcon: Icon(Icons.add, size: 22),
            label: tr(context, '登録'),
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: tr(context, '対応状況'),
          ),
          NavigationDestination(
            icon: Icon(Icons.policy_outlined),
            selectedIcon: Icon(Icons.policy),
            label: tr(context, 'ポリシー'),
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: tr(context, '管理'),
          ),
          NavigationDestination(
            icon: Icon(Icons.settings, size: 22),
            selectedIcon: Icon(Icons.settings, size: 22),
            label: tr(context, '設定'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AsyncValue<List<Project>> projects, Project? project) {
    if (projects.isLoading && !projects.hasValue) {
      return const LoadingView(label: 'プロジェクトを読み込み中...');
    }
    if (projects.hasError && !projects.hasValue) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ErrorCard(
          error: projects.error!,
          onRetry: () => ref.read(projectsProvider.notifier).reload(),
        ),
      );
    }
    final list = projects.value ?? const <Project>[];
    final activeProject = project ?? (list.isEmpty ? null : list.first);

    // The management tab is available without a project: the cluster
    // (Keycloak realm) overview needs no Gorape project.
    if (_index == 4) {
      return ManagementScreen(project: activeProject);
    }

    if (activeProject == null) {
      return EmptyState(
        icon: Icons.folder_off_outlined,
        title: 'Gorapeプロジェクトがありません',
        message:
            'KeycloakユーザーがGorapeのProjectロールを持っていないか、'
            'プロジェクトがまだ作成されていません。\n'
            'Gorapeリポジトリのgorape-adminでプロジェクトを '
            'bootstrapし、ユーザーにadmin/editor/viewerを付与してください。\n'
            '「管理」タブではKeycloakトークンのロールとグループを確認できます。',
        action: Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => ref.read(projectsProvider.notifier).reload(),
              icon: Icon(Icons.refresh, size: 22),
              label: const AppText('再読み込み'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
              icon: Icon(Icons.settings, size: 22),
              label: const AppText('接続設定'),
            ),
          ],
        ),
      );
    }

    return switch (_index) {
      0 => DevicesScreen(
        projectId: activeProject.id,
        onRegister: () => setState(() => _index = 1),
      ),
      1 => RegisterDeviceScreen(
        projectId: activeProject.id,
        onRegistered: (_) => setState(() => _index = 0),
        onOpenDevices: () => setState(() => _index = 0),
      ),
      2 => SupportScreen(projectId: activeProject.id),
      3 => const PolicyScreen(),
      _ => const SettingsScreen(embedded: true),
    };
  }

  Future<void> _showProjectSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _ProjectSheet(),
    );
  }
}

class _ProjectSheet extends ConsumerWidget {
  const _ProjectSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final selected = ref.watch(selectedProjectProvider);
    final list = projects.value ?? const <Project>[];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: AppText(
                'プロジェクト一覧',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final project = list[index];
                  return ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: AppText(project.name),
                    subtitle: AppText(
                      '${project.slug} • ${project.oidcIssuer}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: project.id == selected?.id
                        ? Icon(Icons.assignment, size: 22)
                        : StatusChip.status(context, project.status),
                    selected: project.id == selected?.id,
                    onTap: () {
                      ref
                          .read(selectedProjectIdProvider.notifier)
                          .select(project.id);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
            if (projects.hasError)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ErrorCard(
                  error: projects.error!,
                  onRetry: () => ref.read(projectsProvider.notifier).reload(),
                  compact: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
