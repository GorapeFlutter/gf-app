import '../entity/model/role_binding.dart';
import '../entity/request/group.dart';
import 'gorape.dart';

abstract interface class RoleRepository {
  /// GF-00597 — Handles project roles in RoleRepository.
  Future<List<ProjectRoleBinding>> projectRoles(String projectId);

  /// GF-00598 — Handles put project role in RoleRepository.
  Future<void> putProjectRole(String projectId, RoleCreateRequest request);

  /// GF-00599 — Handles delete project role in RoleRepository.
  Future<void> deleteProjectRole(String projectId, String bindingId);

  /// GF-00600 — Handles group roles in RoleRepository.
  Future<List<GroupRoleBinding>> groupRoles(String projectId, String groupId);

  /// GF-00601 — Handles put group role in RoleRepository.
  Future<void> putGroupRole(
    String projectId,
    String groupId,
    RoleCreateRequest request,
  );

  /// GF-00602 — Handles delete group role in RoleRepository.
  Future<void> deleteGroupRole(
    String projectId,
    String groupId,
    String bindingId,
  );
}

final class RoleRepositoryImpl implements RoleRepository {
  /// GF-00603 — Initializes RoleRepositoryImpl.
  const RoleRepositoryImpl(this._api);

  final GorapeApi _api;

  /// GF-00604 — Handles project roles in RoleRepositoryImpl.
  @override
  Future<List<ProjectRoleBinding>> projectRoles(String projectId) =>
      _api.listProjectRoles(projectId);

  /// GF-00605 — Handles put project role in RoleRepositoryImpl.
  @override
  Future<void> putProjectRole(String projectId, RoleCreateRequest request) =>
      _api.putProjectRole(projectId, request);

  /// GF-00606 — Handles delete project role in RoleRepositoryImpl.
  @override
  Future<void> deleteProjectRole(String projectId, String bindingId) =>
      _api.deleteProjectRole(projectId, bindingId);

  /// GF-00607 — Handles group roles in RoleRepositoryImpl.
  @override
  Future<List<GroupRoleBinding>> groupRoles(String projectId, String groupId) =>
      _api.listGroupRoles(projectId, groupId);

  /// GF-00608 — Handles put group role in RoleRepositoryImpl.
  @override
  Future<void> putGroupRole(
    String projectId,
    String groupId,
    RoleCreateRequest request,
  ) => _api.putGroupRole(projectId, groupId, request);

  /// GF-00609 — Handles delete group role in RoleRepositoryImpl.
  @override
  Future<void> deleteGroupRole(
    String projectId,
    String groupId,
    String bindingId,
  ) => _api.deleteGroupRole(projectId, groupId, bindingId);
}

/// GF-00610 — Creates an instance for new role repository.
RoleRepository newRoleRepository(GorapeApi api) => RoleRepositoryImpl(api);
