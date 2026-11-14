import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entity/model/group.dart';
import '../entity/model/role.dart';
import '../entity/model/role_binding.dart';
import '../entity/request/group.dart';
import 'auth.dart';
import 'dependencies.dart';
import 'project.dart';

/// GF-00009 — Projects Keycloak claims into client-side UI access roles.
/// Keycloak-derived roles for the signed-in session.
///
/// This is intentionally a client-side projection of the token for UI
/// gating. Gorape still authorizes every operation against its own database
/// role bindings.
final roleSnapshotProvider = Provider<RoleSnapshot>(
  /* GF-00231 — Runs an inline callback in top level. */ (ref) {
    final session = ref.watch(authControllerProvider).value;
    if (session == null) return RoleSnapshot.empty;
    return RoleSnapshot.fromClaims(session.claims);
  },
);

final clusterRoleProvider = Provider<AccessRole>(
  /* GF-00232 — Runs an inline callback in top level. */ (ref) =>
      ref.watch(roleSnapshotProvider).clusterRole,
);

final selectedProjectRoleProvider = Provider<AccessRole>(
  /* GF-00233 — Runs an inline callback in top level. */ (ref) {
    final project = ref.watch(selectedProjectProvider);
    if (project == null) return ref.watch(clusterRoleProvider);
    return ref.watch(roleSnapshotProvider).projectRoleFor(project.accessKeys);
  },
);

final projectRoleProvider = Provider.family<AccessRole, String>(
  /* GF-00234 — Runs an inline callback in top level. */ (ref, projectId) {
    final projects = ref.watch(projectsProvider).value ?? const [];
    for (final project in projects) {
      if (project.id == projectId) {
        return ref
            .watch(roleSnapshotProvider)
            .projectRoleFor(project.accessKeys);
      }
    }
    return ref.watch(clusterRoleProvider);
  },
);

final groupRoleProvider = Provider.family<AccessRole, GroupRoleKey>(
  /* GF-00235 — Runs an inline callback in top level. */ (ref, key) {
    final snapshot = ref.watch(roleSnapshotProvider);
    final projectRole = key.projectRole;
    return snapshot.groupRoleFor(
      key.group.accessKeys,
      projectRole: projectRole,
    );
  },
);

/// Inputs for resolving a group role from token claims.
class GroupRoleKey {
  /// GF-00236 — Initializes GroupRoleKey.
  const GroupRoleKey({required this.group, required this.projectRole});

  final Group group;
  final AccessRole projectRole;

  /// GF-00237 — Handles == in GroupRoleKey.
  @override
  bool operator ==(Object other) {
    return other is GroupRoleKey &&
        other.group.id == group.id &&
        other.projectRole == projectRole;
  }

  /// GF-00238 — Computes GroupRoleKey.hashCode.
  @override
  int get hashCode => Object.hash(group.id, projectRole);
}

final projectRoleBindingsProvider =
    FutureProvider.family<List<ProjectRoleBinding>, String>(
      /* GF-00239 — Runs an inline callback in top level. */ (ref, projectId) =>
          ref.watch(roleUsecaseProvider).projectRoles(projectId),
    );

final groupRoleBindingsProvider =
    FutureProvider.family<List<GroupRoleBinding>, GroupRef>(
      /* GF-00240 — Runs an inline callback in top level. */ (ref, key) =>
          ref.watch(roleUsecaseProvider).groupRoles(key.projectId, key.groupId),
    );

abstract interface class RoleController {
  /// GF-00241 — Handles put project role in RoleController.
  Future<void> putProjectRole(String projectId, RoleCreateRequest request);

  /// GF-00242 — Handles delete project role in RoleController.
  Future<void> deleteProjectRole(String projectId, String bindingId);

  /// GF-00243 — Handles put group role in RoleController.
  Future<void> putGroupRole(
    String projectId,
    String groupId,
    RoleCreateRequest request,
  );

  /// GF-00244 — Handles delete group role in RoleController.
  Future<void> deleteGroupRole(
    String projectId,
    String groupId,
    String bindingId,
  );
}

/// GF-00010 — Manages Gorape project and group role bindings.
final class RoleControllerImpl implements RoleController {
  /// GF-00245 — Initializes RoleControllerImpl.
  RoleControllerImpl(this._ref);

  final Ref _ref;

  /// GF-00246 — Handles put project role in RoleControllerImpl.
  @override
  Future<void> putProjectRole(
    String projectId,
    RoleCreateRequest request,
  ) async {
    // GF-02058 — Create a project role binding in Gorape.
    await _ref.read(roleUsecaseProvider).putProjectRole(projectId, request);
    // GF-02059 — Refresh the project's role-binding list.
    _ref.invalidate(projectRoleBindingsProvider(projectId));
  }

  /// GF-00247 — Handles delete project role in RoleControllerImpl.
  @override
  Future<void> deleteProjectRole(String projectId, String bindingId) async {
    // GF-02060 — Delete a project role binding in Gorape.
    await _ref
        .read(roleUsecaseProvider)
        .deleteProjectRole(projectId, bindingId);
    // GF-02061 — Refresh the project's role-binding list.
    _ref.invalidate(projectRoleBindingsProvider(projectId));
  }

  /// GF-00248 — Handles put group role in RoleControllerImpl.
  @override
  Future<void> putGroupRole(
    String projectId,
    String groupId,
    RoleCreateRequest request,
  ) async {
    // GF-02062 — Create a group role binding in Gorape.
    await _ref
        .read(roleUsecaseProvider)
        .putGroupRole(projectId, groupId, request);
    // GF-02063 — Refresh the group's role-binding list.
    _ref.invalidate(
      groupRoleBindingsProvider(
        GroupRef(projectId: projectId, groupId: groupId),
      ),
    );
  }

  /// GF-00249 — Handles delete group role in RoleControllerImpl.
  @override
  Future<void> deleteGroupRole(
    String projectId,
    String groupId,
    String bindingId,
  ) async {
    // GF-02064 — Delete a group role binding in Gorape.
    await _ref
        .read(roleUsecaseProvider)
        .deleteGroupRole(projectId, groupId, bindingId);
    // GF-02065 — Refresh the group's role-binding list.
    _ref.invalidate(
      groupRoleBindingsProvider(
        GroupRef(projectId: projectId, groupId: groupId),
      ),
    );
  }
}

final roleControllerProvider = Provider<RoleController>(RoleControllerImpl.new);
