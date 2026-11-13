/// A Gorape group returned by the project group endpoints.
class Group {
  const Group({
    required this.id,
    required this.projectId,
    required this.slug,
    required this.name,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String projectId;
  final String slug;
  final String name;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == 'active';

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: _string(json['id']),
      projectId: _string(json['project_id']),
      slug: _string(json['slug']),
      name: _string(json['name']),
      status: _string(json['status'], fallback: 'active'),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  static String _string(Object? value, {String fallback = ''}) =>
      value is String ? value : fallback;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

/// Stable provider key for group-scoped resources.
class GroupRef {
  const GroupRef({required this.projectId, required this.groupId});

  final String projectId;
  final String groupId;

  @override
  bool operator ==(Object other) {
    return other is GroupRef &&
        other.projectId == projectId &&
        other.groupId == groupId;
  }

  @override
  int get hashCode => Object.hash(projectId, groupId);

  @override
  String toString() => 'GroupRef($projectId, $groupId)';
}
