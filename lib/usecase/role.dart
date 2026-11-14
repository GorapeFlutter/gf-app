import '../entity/model/role_binding.dart';
import '../entity/request/group.dart';
import '../repository/role.dart';

abstract interface class RoleUsecase {
  /// GF-01125 — Handles project roles in RoleUsecase.
  Future<List<ProjectRoleBinding>> projectRoles(String projectId);

  /// GF-01126 — Handles put project role in RoleUsecase.
  Future<void> putProjectRole(String projectId, RoleCreateRequest request);

  /// GF-01127 — Handles delete project role in RoleUsecase.
  Future<void> deleteProjectRole(String projectId, String bindingId);

  /// GF-01128 — Handles group roles in RoleUsecase.
  Future<List<GroupRoleBinding>> groupRoles(String projectId, String groupId);

  /// GF-01129 — Handles put group role in RoleUsecase.
  Future<void> putGroupRole(
    String projectId,
    String groupId,
    RoleCreateRequest request,
  );

  /// GF-01130 — Handles delete group role in RoleUsecase.
  Future<void> deleteGroupRole(
    String projectId,
    String groupId,
    String bindingId,
  );
}

final class RoleUsecaseImpl implements RoleUsecase {
  /// GF-01131 — Initializes RoleUsecaseImpl.
  const RoleUsecaseImpl(this._repository);

  final RoleRepository _repository;

  /// GF-01132 — Handles project roles in RoleUsecaseImpl.
  @override
  Future<List<ProjectRoleBinding>> projectRoles(String projectId) =>
      _repository.projectRoles(projectId);

  /// GF-01133 — Handles put project role in RoleUsecaseImpl.
  @override
  Future<void> putProjectRole(String projectId, RoleCreateRequest request) =>
      _repository.putProjectRole(projectId, request);

  /// GF-01134 — Handles delete project role in RoleUsecaseImpl.
  @override
  Future<void> deleteProjectRole(String projectId, String bindingId) =>
      _repository.deleteProjectRole(projectId, bindingId);

  /// GF-01135 — Handles group roles in RoleUsecaseImpl.
  @override
  Future<List<GroupRoleBinding>> groupRoles(String projectId, String groupId) =>
      _repository.groupRoles(projectId, groupId);

  /// GF-01136 — Handles put group role in RoleUsecaseImpl.
  @override
  Future<void> putGroupRole(
    String projectId,
    String groupId,
    RoleCreateRequest request,
  ) => _repository.putGroupRole(projectId, groupId, request);

  /// GF-01137 — Handles delete group role in RoleUsecaseImpl.
  @override
  Future<void> deleteGroupRole(
    String projectId,
    String groupId,
    String bindingId,
  ) => _repository.deleteGroupRole(projectId, groupId, bindingId);
}

/// GF-01138 — Creates an instance for new role usecase.
RoleUsecase newRoleUsecase(RoleRepository repository) =>
    RoleUsecaseImpl(repository);
