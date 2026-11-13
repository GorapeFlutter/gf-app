import 'role.dart';

/// A project-level role binding returned by `GET /v1/projects/{id}/roles`.
class ProjectRoleBinding {
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

  AccessRole get accessRole => AccessRole.fromName(role) ?? AccessRole.none;

  factory ProjectRoleBinding.fromJson(Map<String, dynamic> json) {
    return ProjectRoleBinding(
      id: _string(json['id']),
      projectId: _string(json['project_id']),
      principalId: _string(json['principal_id']),
      role: _string(json['role'] ?? json['role_key']),
      createdAt: _date(json['created_at']),
    );
  }

  static String _string(Object? value) => value is String ? value : '';

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

/// A group-level role binding returned by the group role endpoints.
class GroupRoleBinding {
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

  AccessRole get accessRole => AccessRole.fromName(role) ?? AccessRole.none;

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

  static String _string(Object? value) => value is String ? value : '';

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
