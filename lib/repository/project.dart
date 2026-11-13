import '../entity/model/project.dart';
import 'gorape.dart';

abstract interface class ProjectRepository {
  Future<List<Project>> list();

  Future<Project> get(String projectId);
}

final class ProjectRepositoryImpl implements ProjectRepository {
  const ProjectRepositoryImpl(this._api);

  final GorapeApi _api;

  @override
  Future<List<Project>> list() => _api.listProjects();

  @override
  Future<Project> get(String projectId) => _api.getProject(projectId);
}

ProjectRepository newProjectRepository(GorapeApi api) =>
    ProjectRepositoryImpl(api);
