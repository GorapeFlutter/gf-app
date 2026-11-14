/// A Gorape group returned by the project group endpoints.
class Group {
  /// GF-00292 — Initializes Group.
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

  /// GF-00293 — Computes Group.isActive.
  bool get isActive => status == 'active';

  /// GF-00294 — Initializes Group.fromJson.
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

  /// GF-00295 — Handles string in Group.
  static String _string(Object? value, {String fallback = ''}) =>
      value is String ? value : fallback;

  /// GF-00296 — Handles date in Group.
  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

/// Stable provider key for group-scoped resources.
class GroupRef {
  /// GF-00297 — Initializes GroupRef.
  const GroupRef({required this.projectId, required this.groupId});

  final String projectId;
  final String groupId;

  /// GF-00298 — Handles == in GroupRef.
  @override
  bool operator ==(Object other) {
    return other is GroupRef &&
        other.projectId == projectId &&
        other.groupId == groupId;
  }

  /// GF-00299 — Computes GroupRef.hashCode.
  @override
  int get hashCode => Object.hash(projectId, groupId);

  /// GF-00300 — Handles to string in GroupRef.
  @override
  String toString() => 'GroupRef($projectId, $groupId)';
}
