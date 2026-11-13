import '../entity/model/role_binding.dart';
import '../entity/request/group.dart';
import 'gorape.dart';

abstract interface class RoleRepository {
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

final class RoleRepositoryImpl implements RoleRepository {
  const RoleRepositoryImpl(this._api);

  final GorapeApi _api;

  @override
  Future<List<ProjectRoleBinding>> projectRoles(String projectId) =>
      _api.listProjectRoles(projectId);

  @override
  Future<void> putProjectRole(String projectId, RoleCreateRequest request) =>
      _api.putProjectRole(projectId, request);

  @override
  Future<void> deleteProjectRole(String projectId, String bindingId) =>
      _api.deleteProjectRole(projectId, bindingId);

  @override
  Future<List<GroupRoleBinding>> groupRoles(String projectId, String groupId) =>
      _api.listGroupRoles(projectId, groupId);

  @override
  Future<void> putGroupRole(
    String projectId,
    String groupId,
    RoleCreateRequest request,
  ) => _api.putGroupRole(projectId, groupId, request);

  @override
  Future<void> deleteGroupRole(
    String projectId,
    String groupId,
    String bindingId,
  ) => _api.deleteGroupRole(projectId, groupId, bindingId);
}

RoleRepository newRoleRepository(GorapeApi api) => RoleRepositoryImpl(api);
