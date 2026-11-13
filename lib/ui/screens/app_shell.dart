import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/project.dart';
import '../../state/auth_controller.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import 'devices_screen.dart';
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

  static const _titles = ['デバイス', 'デバイス登録', '対応状況', 'デバイスポリシー', '設定'];

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
            Icon(Icons.shield_outlined, color: scheme.primary),
            const SizedBox(width: 8),
            Flexible(child: Text(_titles[_index])),
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
                  child: Text(project.name, overflow: TextOverflow.ellipsis),
                ),
                tooltip: 'プロジェクトを切り替え',
                onPressed: () => _showProjectSheet(context),
              ),
            ),
          PopupMenuButton<String>(
            tooltip: 'アカウント',
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
                  title: Text(session?.displayName ?? 'Signed in'),
                  subtitle: Text(
                    session?.email ?? session?.subject ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.settings_outlined),
                  title: Text('接続設定'),
                ),
              ),
              const PopupMenuItem(
                value: 'signout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout),
                  title: Text('ログアウト'),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices),
            label: 'デバイス',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_moderator_outlined),
            selectedIcon: Icon(Icons.add_moderator),
            label: '登録',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: '対応状況',
          ),
          NavigationDestination(
            icon: Icon(Icons.policy_outlined),
            selectedIcon: Icon(Icons.policy),
            label: 'ポリシー',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
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
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.folder_off_outlined,
        title: 'Gorapeプロジェクトがありません',
        message:
            'KeycloakユーザーがGorapeのProjectロールを持っていないか、'
            'プロジェクトがまだ作成されていません。\n'
            'Gorapeリポジトリのgorape-adminでプロジェクトを '
            'bootstrapし、ユーザーにadmin/editor/viewerを付与してください。',
        action: Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => ref.read(projectsProvider.notifier).reload(),
              icon: const Icon(Icons.refresh),
              label: const Text('再読み込み'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
              icon: const Icon(Icons.settings_outlined),
              label: const Text('接続設定'),
            ),
          ],
        ),
      );
    }

    final activeProject = project ?? list.first;
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
              child: Text(
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
                    title: Text(project.name),
                    subtitle: Text(
                      '${project.slug} • ${project.oidcIssuer}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: project.id == selected?.id
                        ? const Icon(Icons.check_circle)
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
