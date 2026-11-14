import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entity/model/project.dart';
import 'auth.dart';
import 'dependencies.dart';

abstract interface class ProjectController {
  /// GF-00221 — Handles reload in ProjectController.
  Future<void> reload();
}

/// GF-00004 — Loads visible projects for the authenticated session.
final class ProjectControllerImpl extends AsyncNotifier<List<Project>>
    implements ProjectController {
  /// GF-00222 — Builds the widget or value for ProjectControllerImpl.
  @override
  Future<List<Project>> build() async {
    if (!ref.watch(isAuthenticatedProvider)) return const [];
    return ref.watch(projectUsecaseProvider).list();
  }

  /// GF-00223 — Handles reload in ProjectControllerImpl.
  @override
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      /* GF-00224 — Runs an inline callback in ProjectControllerImpl.reload. */ () async {
        if (ref.read(authControllerProvider).value == null) return const [];
        return ref.read(projectUsecaseProvider).list();
      },
    );
  }
}

final projectsProvider =
    AsyncNotifierProvider<ProjectControllerImpl, List<Project>>(
      ProjectControllerImpl.new,
    );

abstract interface class SelectedProjectController {
  /// GF-00225 — Handles select in SelectedProjectController.
  void select(String projectId);
}

final class SelectedProjectControllerImpl extends Notifier<String?>
    implements SelectedProjectController {
  /// GF-00226 — Builds the widget or value for SelectedProjectControllerImpl.
  @override
  String? build() => null;

  /// GF-00227 — Handles select in SelectedProjectControllerImpl.
  @override
  void select(String projectId) => state = projectId;
}

final selectedProjectIdProvider =
    NotifierProvider<SelectedProjectControllerImpl, String?>(
      SelectedProjectControllerImpl.new,
    );

final selectedProjectProvider = Provider<Project?>(
  /* GF-00228 — Runs an inline callback in top level. */ (ref) {
    final projects = ref.watch(projectsProvider).value ?? const <Project>[];
    if (projects.isEmpty) return null;
    final selectedId = ref.watch(selectedProjectIdProvider);
    return projects.firstWhere(
      /* GF-00229 — Runs an inline callback in top level.callback. */ (
        project,
      ) => project.id == selectedId,
      orElse: /* GF-00230 — Runs an inline callback in top level.callback. */
          () => projects.first,
    );
  },
);
