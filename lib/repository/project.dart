import '../entity/model/project.dart';
import 'gorape.dart';

abstract interface class ProjectRepository {
  /// GF-00591 — Handles list in ProjectRepository.
  Future<List<Project>> list();

  /// GF-00592 — Handles get in ProjectRepository.
  Future<Project> get(String projectId);
}

final class ProjectRepositoryImpl implements ProjectRepository {
  /// GF-00593 — Initializes ProjectRepositoryImpl.
  const ProjectRepositoryImpl(this._api);

  final GorapeApi _api;

  /// GF-00594 — Handles list in ProjectRepositoryImpl.
  @override
  Future<List<Project>> list() => _api.listProjects();

  /// GF-00595 — Handles get in ProjectRepositoryImpl.
  @override
  Future<Project> get(String projectId) => _api.getProject(projectId);
}

/// GF-00596 — Creates an instance for new project repository.
ProjectRepository newProjectRepository(GorapeApi api) =>
    ProjectRepositoryImpl(api);
