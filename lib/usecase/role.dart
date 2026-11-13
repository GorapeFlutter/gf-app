import '../entity/model/role_binding.dart';
import '../entity/request/group.dart';
import '../repository/role.dart';

abstract interface class RoleUsecase {
  Future<List<ProjectRoleBinding>> projectRoles(String projectId);

  Future<void> putProjectRole(String projectId, RoleCreateRequest request);

  Future<void> deleteProjectRole(String projectId, String bindingId);

  Future<List<GroupRoleBinding>> groupRoles(String projectId, String groupId);

  Future<void> putGroupRole(
    String projectId,
    String groupId,
    RoleCreateRequest request,
  );

  Future<void> deleteGroupRole(
    String projectId,
    String groupId,
    String bindingId,
  );
}

final class RoleUsecaseImpl implements RoleUsecase {
  const RoleUsecaseImpl(this._repository);

  final RoleRepository _repository;

  @override
  Future<List<ProjectRoleBinding>> projectRoles(String projectId) =>
      _repository.projectRoles(projectId);

  @override
  Future<void> putProjectRole(String projectId, RoleCreateRequest request) =>
      _repository.putProjectRole(projectId, request);

  @override
  Future<void> deleteProjectRole(String projectId, String bindingId) =>
      _repository.deleteProjectRole(projectId, bindingId);

  @override
  Future<List<GroupRoleBinding>> groupRoles(String projectId, String groupId) =>
      _repository.groupRoles(projectId, groupId);

  @override
  Future<void> putGroupRole(
    String projectId,
    String groupId,
    RoleCreateRequest request,
  ) => _repository.putGroupRole(projectId, groupId, request);

  @override
  Future<void> deleteGroupRole(
    String projectId,
    String groupId,
    String bindingId,
  ) => _repository.deleteGroupRole(projectId, groupId, bindingId);
}

RoleUsecase newRoleUsecase(RoleRepository repository) =>
    RoleUsecaseImpl(repository);
