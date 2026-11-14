import '../repository/project.dart';
import '../entity/model/project.dart';

abstract interface class ProjectUsecase {
  /// GF-01119 — Handles list in ProjectUsecase.
  Future<List<Project>> list();

  /// GF-01120 — Handles get in ProjectUsecase.
  Future<Project> get(String projectId);
}

final class ProjectUsecaseImpl implements ProjectUsecase {
  /// GF-01121 — Initializes ProjectUsecaseImpl.
  const ProjectUsecaseImpl(this._repository);
  final ProjectRepository _repository;

  /// GF-01122 — Handles list in ProjectUsecaseImpl.
  @override
  Future<List<Project>> list() => _repository.list();

  /// GF-01123 — Handles get in ProjectUsecaseImpl.
  @override
  Future<Project> get(String projectId) => _repository.get(projectId);
}

/// GF-01124 — Creates an instance for new project usecase.
ProjectUsecase newProjectUsecase(ProjectRepository repository) =>
    ProjectUsecaseImpl(repository);
