import 'role.dart';

/// A project-level role binding returned by `GET /v1/projects/{id}/roles`.
class ProjectRoleBinding {
  /// GF-00365 — Initializes ProjectRoleBinding.
  const ProjectRoleBinding({
    required this.id,
    required this.projectId,
    required this.principalId,
    required this.role,
    this.createdAt,
  });

  final String id;
  final String projectId;
  final String principalId;
  final String role;
  final DateTime? createdAt;

  /// GF-00366 — Computes ProjectRoleBinding.accessRole.
  AccessRole get accessRole => AccessRole.fromName(role) ?? AccessRole.none;

  /// GF-00367 — Initializes ProjectRoleBinding.fromJson.
  factory ProjectRoleBinding.fromJson(Map<String, dynamic> json) {
    return ProjectRoleBinding(
      id: _string(json['id']),
      projectId: _string(json['project_id']),
      principalId: _string(json['principal_id']),
      role: _string(json['role'] ?? json['role_key']),
      createdAt: _date(json['created_at']),
    );
  }

  /// GF-00368 — Handles string in ProjectRoleBinding.
  static String _string(Object? value) => value is String ? value : '';

  /// GF-00369 — Handles date in ProjectRoleBinding.
  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

/// A group-level role binding returned by the group role endpoints.
class GroupRoleBinding {
  /// GF-00370 — Initializes GroupRoleBinding.
  const GroupRoleBinding({
    required this.id,
    required this.projectId,
    required this.groupId,
    required this.principalId,
    required this.role,
    this.createdAt,
  });

  final String id;
  final String projectId;
  final String groupId;
  final String principalId;
  final String role;
  final DateTime? createdAt;

  /// GF-00371 — Computes GroupRoleBinding.accessRole.
  AccessRole get accessRole => AccessRole.fromName(role) ?? AccessRole.none;

  /// GF-00372 — Initializes GroupRoleBinding.fromJson.
  factory GroupRoleBinding.fromJson(Map<String, dynamic> json) {
    return GroupRoleBinding(
      id: _string(json['id']),
      projectId: _string(json['project_id']),
      groupId: _string(json['group_id']),
      principalId: _string(json['principal_id']),
      role: _string(json['role'] ?? json['role_key']),
      createdAt: _date(json['created_at']),
    );
  }

  /// GF-00373 — Handles string in GroupRoleBinding.
  static String _string(Object? value) => value is String ? value : '';

  /// GF-00374 — Handles date in GroupRoleBinding.
  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
