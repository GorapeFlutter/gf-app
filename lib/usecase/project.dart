import '../repository/project.dart';
import '../entity/model/project.dart';

abstract interface class ProjectUsecase {
  Future<List<Project>> list();
  Future<Project> get(String projectId);
}

final class ProjectUsecaseImpl implements ProjectUsecase {
  const ProjectUsecaseImpl(this._repository);
  final ProjectRepository _repository;

  @override
  Future<List<Project>> list() => _repository.list();
  @override
  Future<Project> get(String projectId) => _repository.get(projectId);
}

ProjectUsecase newProjectUsecase(ProjectRepository repository) =>
    ProjectUsecaseImpl(repository);
