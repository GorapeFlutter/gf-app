import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entity/model/project.dart';
import 'auth.dart';
import 'dependencies.dart';

abstract interface class ProjectController {
  Future<void> reload();
}

final class ProjectControllerImpl extends AsyncNotifier<List<Project>>
    implements ProjectController {
  @override
  Future<List<Project>> build() async {
    if (!ref.watch(isAuthenticatedProvider)) return const [];
    return ref.watch(projectUsecaseProvider).list();
  }

  @override
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (ref.read(authControllerProvider).value == null) return const [];
      return ref.read(projectUsecaseProvider).list();
    });
  }
}

final projectsProvider =
    AsyncNotifierProvider<ProjectControllerImpl, List<Project>>(
      ProjectControllerImpl.new,
    );

abstract interface class SelectedProjectController {
  void select(String projectId);
}

final class SelectedProjectControllerImpl extends Notifier<String?>
    implements SelectedProjectController {
  @override
  String? build() => null;

  @override
  void select(String projectId) => state = projectId;
}

final selectedProjectIdProvider =
    NotifierProvider<SelectedProjectControllerImpl, String?>(
      SelectedProjectControllerImpl.new,
    );

final selectedProjectProvider = Provider<Project?>((ref) {
  final projects = ref.watch(projectsProvider).value ?? const <Project>[];
  if (projects.isEmpty) return null;
  final selectedId = ref.watch(selectedProjectIdProvider);
  return projects.firstWhere(
    (project) => project.id == selectedId,
    orElse: () => projects.first,
  );
});
