import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entity/model/group.dart';
import '../entity/model/role.dart';
import '../entity/model/role_binding.dart';
import '../entity/request/group.dart';
import 'auth.dart';
import 'dependencies.dart';
import 'project.dart';

/// Keycloak-derived roles for the signed-in session.
///
/// This is intentionally a client-side projection of the token for UI
/// gating. Gorape still authorizes every operation against its own database
/// role bindings.
final roleSnapshotProvider = Provider<RoleSnapshot>((ref) {
  final session = ref.watch(authControllerProvider).value;
  if (session == null) return RoleSnapshot.empty;
  return RoleSnapshot.fromClaims(session.claims);
});

final clusterRoleProvider = Provider<AccessRole>(
  (ref) => ref.watch(roleSnapshotProvider).clusterRole,
);

final selectedProjectRoleProvider = Provider<AccessRole>((ref) {
  final project = ref.watch(selectedProjectProvider);
  if (project == null) return ref.watch(clusterRoleProvider);
  return ref.watch(roleSnapshotProvider).projectRoleFor(project.accessKeys);
});

final projectRoleProvider = Provider.family<AccessRole, String>((
  ref,
  projectId,
) {
  final projects = ref.watch(projectsProvider).value ?? const [];
  for (final project in projects) {
    if (project.id == projectId) {
      return ref.watch(roleSnapshotProvider).projectRoleFor(project.accessKeys);
    }
  }
  return ref.watch(clusterRoleProvider);
});

final groupRoleProvider = Provider.family<AccessRole, GroupRoleKey>((ref, key) {
  final snapshot = ref.watch(roleSnapshotProvider);
  final projectRole = key.projectRole;
  return snapshot.groupRoleFor(key.group.accessKeys, projectRole: projectRole);
});

/// Inputs for resolving a group role from token claims.
class GroupRoleKey {
  const GroupRoleKey({required this.group, required this.projectRole});

  final Group group;
  final AccessRole projectRole;

  @override
  bool operator ==(Object other) {
    return other is GroupRoleKey &&
        other.group.id == group.id &&
        other.projectRole == projectRole;
  }

  @override
  int get hashCode => Object.hash(group.id, projectRole);
}

final projectRoleBindingsProvider =
    FutureProvider.family<List<ProjectRoleBinding>, String>(
      (ref, projectId) =>
          ref.watch(roleUsecaseProvider).projectRoles(projectId),
    );

final groupRoleBindingsProvider =
    FutureProvider.family<List<GroupRoleBinding>, GroupRef>(
      (ref, key) =>
          ref.watch(roleUsecaseProvider).groupRoles(key.projectId, key.groupId),
    );

abstract interface class RoleController {
  Future<void> putProjectRole(String projectId, RoleCreateRequest request);

  Future<void> deleteProjectRole(String projectId, String bindingId);

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

final class RoleControllerImpl implements RoleController {
  RoleControllerImpl(this._ref);

  final Ref _ref;

  @override
  Future<void> putProjectRole(
    String projectId,
    RoleCreateRequest request,
  ) async {
    await _ref.read(roleUsecaseProvider).putProjectRole(projectId, request);
    _ref.invalidate(projectRoleBindingsProvider(projectId));
  }

  @override
  Future<void> deleteProjectRole(String projectId, String bindingId) async {
    await _ref
        .read(roleUsecaseProvider)
        .deleteProjectRole(projectId, bindingId);
    _ref.invalidate(projectRoleBindingsProvider(projectId));
  }

  @override
  Future<void> putGroupRole(
    String projectId,
    String groupId,
    RoleCreateRequest request,
  ) async {
    await _ref
        .read(roleUsecaseProvider)
        .putGroupRole(projectId, groupId, request);
    _ref.invalidate(
      groupRoleBindingsProvider(
        GroupRef(projectId: projectId, groupId: groupId),
      ),
    );
  }

  @override
  Future<void> deleteGroupRole(
    String projectId,
    String groupId,
    String bindingId,
  ) async {
    await _ref
        .read(roleUsecaseProvider)
        .deleteGroupRole(projectId, groupId, bindingId);
    _ref.invalidate(
      groupRoleBindingsProvider(
        GroupRef(projectId: projectId, groupId: groupId),
      ),
    );
  }
}

final roleControllerProvider = Provider<RoleController>(RoleControllerImpl.new);
