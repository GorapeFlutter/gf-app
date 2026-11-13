import 'dart:convert';

import 'group.dart';
import 'project.dart';

/// Authorization role used by Gorape.
///
/// The app resolves these roles from Keycloak token claims for display and
/// for gating UI actions. Gorape still enforces authorization against its own
/// project/group role bindings.
enum AccessRole {
  none(0, '権限なし'),
  viewer(1, '閲覧者'),
  editor(2, '編集者'),
  admin(3, '管理者');

  const AccessRole(this.rank, this.label);

  final int rank;
  final String label;

  bool atLeast(AccessRole other) => rank >= other.rank;

  bool get canView => atLeast(viewer);
  bool get canEdit => atLeast(editor);
  bool get canAdmin => atLeast(admin);

  String get description => switch (this) {
    AccessRole.admin => 'グループ作成・ロール付与・デバイス失効など、このスコープの管理操作をすべて実行できます。',
    AccessRole.editor => 'デバイスの登録・失効、グループへのデバイス割当を実行できます。グループ設定とロール付与は変更できません。',
    AccessRole.viewer => 'デバイス、グループ、ロールを参照できます。変更操作は表示されません。',
    AccessRole.none => 'このスコープのロールがKeycloakトークンに含まれていません。',
  };

  static AccessRole? fromName(Object? value) {
    if (value is Iterable) {
      AccessRole? best;
      for (final item in value) {
        final role = fromName(item);
        if (role != null && (best == null || role.rank > best.rank)) {
          best = role;
        }
      }
      return best;
    }
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    final name = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    if (name.contains('admin') ||
        name == 'owner' ||
        name == 'administrator' ||
        name == 'maintainer') {
      return AccessRole.admin;
    }
    if (name.contains('editor') ||
        name == 'writer' ||
        name == 'write' ||
        name == 'edit') {
      return AccessRole.editor;
    }
    if (name.contains('viewer') ||
        name == 'reader' ||
        name == 'read' ||
        name == 'read-only' ||
        name == 'readonly' ||
        name == 'member' ||
        name == 'user' ||
        name == 'app') {
      return AccessRole.viewer;
    }
    return null;
  }

  static AccessRole best(Iterable<AccessRole?> roles) {
    var result = AccessRole.none;
    for (final role in roles) {
      if (role != null && role.rank > result.rank) result = role;
    }
    return result;
  }
}

/// Keycloak claims relevant to Gorape RBAC.
///
/// Supported conventions (all optional):
/// - realm/client roles named `admin`, `editor`, `viewer`, `app` (viewer).
/// - `groups` entries whose last path segment is a role, for example
///   `/group001/editor` or `/gorape/group001/admin`.
/// - `gorape_project_role` for a project-wide fallback role.
/// - `gorape_project_roles` as a JSON object or claim map keyed by slug/id.
/// - `gorape_group_role` for a group-wide fallback role.
/// - `gorape_group_roles` as a JSON object or claim map keyed by slug/path.
/// - `gorape_project_<slug>_role` / `gorape_group_<slug>_role` attributes.
class RoleSnapshot {
  const RoleSnapshot({
    this.realmRoles = const [],
    this.clientRoles = const [],
    this.groupPaths = const [],
    this.attributes = const {},
    this.clusterRole = AccessRole.none,
    this.projectRoles = const {},
    this.groupRoles = const {},
    this.projectFallback = AccessRole.none,
    this.groupFallback = AccessRole.none,
  });

  static const empty = RoleSnapshot();

  final List<String> realmRoles;
  final List<String> clientRoles;
  final List<String> groupPaths;
  final Map<String, Object?> attributes;
  final AccessRole clusterRole;
  final Map<String, AccessRole> projectRoles;
  final Map<String, AccessRole> groupRoles;
  final AccessRole projectFallback;
  final AccessRole groupFallback;

  List<String> get allRoles => _unique([...realmRoles, ...clientRoles]);

  AccessRole projectRoleFor(Iterable<String> keys) {
    return AccessRole.best([
      clusterRole,
      projectFallback,
      for (final key in keys) _lookup(projectRoles, key),
    ]);
  }

  AccessRole groupRoleFor(
    Iterable<String> keys, {
    AccessRole projectRole = AccessRole.none,
  }) {
    return AccessRole.best([
      projectRole,
      groupFallback,
      for (final key in keys) _lookup(groupRoles, key),
    ]);
  }

  factory RoleSnapshot.fromClaims(Map<String, dynamic> claims) {
    final attributes = _extractAttributes(claims);
    final realmRoles = _unique([
      ..._strings(_asMap(claims['realm_access'])['roles']),
      ..._strings(claims['roles']),
      ..._strings(claims['gorape_roles']),
    ]);

    final clientRoles = <String>[];
    for (final value in _asMap(claims['resource_access']).values) {
      clientRoles.addAll(_strings(_asMap(value)['roles']));
    }
    clientRoles.addAll(_strings(claims['client_roles']));

    final roles = [...realmRoles, ...clientRoles];
    final explicitCluster = _valueOf(claims, attributes, const [
      'gorape_cluster_role',
      'cluster_role',
      'gorape_role',
    ]);
    final clusterRole = AccessRole.best([
      AccessRole.fromName(explicitCluster),
      for (final role in roles) AccessRole.fromName(role),
    ]);

    final projectRoles = <String, AccessRole>{};
    final projectFallback =
        AccessRole.fromName(
          _valueOf(claims, attributes, const [
            'gorape_project_role',
            'project_role',
          ]),
        ) ??
        AccessRole.none;

    _mergeRoleMap(
      projectRoles,
      _asMap(
        _valueOf(claims, attributes, const [
          'gorape_project_roles',
          'project_roles',
          'projects',
        ]),
      ),
    );
    _mergeAttributeRoles(
      projectRoles,
      attributes,
      prefix: 'gorape_project_',
      suffix: '_role',
    );

    final groupRoles = <String, AccessRole>{};
    final groupFallback =
        AccessRole.fromName(
          _valueOf(claims, attributes, const [
            'gorape_group_role',
            'group_role',
          ]),
        ) ??
        AccessRole.none;

    _mergeRoleMap(
      groupRoles,
      _asMap(
        _valueOf(claims, attributes, const [
          'gorape_group_roles',
          'group_roles',
          'groups_by_role',
        ]),
      ),
    );
    _mergeAttributeRoles(
      groupRoles,
      attributes,
      prefix: 'gorape_group_',
      suffix: '_role',
      ignore: const {'gorape_group_role', 'gorape_group_roles'},
    );

    final groupPaths = <String>[];
    final rawGroups = claims['groups'] ?? claims['gorape_groups'];
    if (rawGroups is List) {
      for (final entry in rawGroups) {
        if (entry is String && entry.trim().isNotEmpty) {
          groupPaths.add(entry.trim());
          _mergeAuthorizationPathRoles(projectRoles, groupRoles, entry);
          continue;
        }
        if (entry is Map) {
          final map = _asMap(entry);
          final name = map['path'] ?? map['name'] ?? map['group'];
          if (name is String && name.trim().isNotEmpty) {
            groupPaths.add(name.trim());
            final role = AccessRole.fromName(map['role']);
            if (role != null) {
              _mergeRole(groupRoles, name, role);
              _mergeRole(groupRoles, _lastSegment(name), role);
            }
          }
        }
      }
    }
    final attributeGroups = _valueOf(claims, attributes, const [
      'gorape_groups',
    ]);
    if (attributeGroups is List) {
      for (final entry in _strings(attributeGroups)) {
        groupPaths.add(entry);
        _mergeAuthorizationPathRoles(projectRoles, groupRoles, entry);
      }
    }

    return RoleSnapshot(
      realmRoles: realmRoles,
      clientRoles: _unique(clientRoles),
      groupPaths: _unique(groupPaths),
      attributes: attributes,
      clusterRole: clusterRole,
      projectRoles: projectRoles,
      groupRoles: groupRoles,
      projectFallback: projectFallback,
      groupFallback: groupFallback,
    );
  }

  static void _mergeRoleMap(
    Map<String, AccessRole> target,
    Map<String, dynamic> source,
  ) {
    for (final entry in source.entries) {
      final role = AccessRole.fromName(entry.value);
      if (role == null) continue;
      _mergeRole(target, entry.key, role);
    }
  }

  static void _mergeAttributeRoles(
    Map<String, AccessRole> target,
    Map<String, Object?> attributes, {
    required String prefix,
    required String suffix,
    Set<String> ignore = const {},
  }) {
    for (final entry in attributes.entries) {
      final key = entry.key;
      if (ignore.contains(key)) continue;
      if (!key.startsWith(prefix) || !key.endsWith(suffix)) continue;
      if (key.length <= prefix.length + suffix.length) continue;
      final name = key.substring(prefix.length, key.length - suffix.length);
      if (name.isEmpty || name == 'role' || name == 'roles') continue;
      final role = AccessRole.fromName(entry.value);
      if (role != null) _mergeRole(target, name, role);
    }
  }

  static void _mergeGroupPathRole(Map<String, AccessRole> target, String path) {
    final segments = path
        .split('/')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (segments.length < 2) return;
    final role = AccessRole.fromName(segments.last);
    if (role == null) return;
    final groupSegments = segments.sublist(0, segments.length - 1);
    _mergeRole(target, groupSegments.join('/'), role);
    _mergeRole(target, '/${groupSegments.join('/')}', role);
    _mergeRole(target, groupSegments.last, role);
  }

  static void _mergeAuthorizationPathRoles(
    Map<String, AccessRole> projectRoles,
    Map<String, AccessRole> groupRoles,
    String path,
  ) {
    final segments = path
        .split('/')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);

    if (segments.length >= 5 &&
        segments[0] == 'gorape' &&
        segments[1] == 'projects') {
      final projectSlug = segments[2];
      if (segments.length == 5 && segments[3] == 'roles') {
        final role = AccessRole.fromName(segments[4]);
        if (role != null) _mergeRole(projectRoles, projectSlug, role);
        return;
      }
      if (segments.length == 7 &&
          segments[3] == 'groups' &&
          segments[5] == 'roles') {
        final role = AccessRole.fromName(segments[6]);
        if (role != null) {
          final groupSlug = segments[4];
          _mergeRole(groupRoles, groupSlug, role);
          _mergeRole(groupRoles, '$projectSlug/$groupSlug', role);
        }
        return;
      }
    }

    _mergeGroupPathRole(groupRoles, path);
  }

  static void _mergeRole(
    Map<String, AccessRole> target,
    Object? key,
    AccessRole role,
  ) {
    final normalized = _normalizeKey(key);
    if (normalized.isEmpty) return;
    final current = target[normalized];
    if (current == null || role.rank > current.rank) {
      target[normalized] = role;
    }
  }

  static AccessRole? _lookup(Map<String, AccessRole> roles, Object? key) {
    final normalized = _normalizeKey(key);
    if (normalized.isEmpty) return null;
    final direct = roles[normalized];
    if (direct != null) return direct;
    final segments = normalized
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (segments.length > 1) {
      final last = roles[segments.last];
      if (last != null) return last;
    }
    return null;
  }

  static String _normalizeKey(Object? value) {
    return (value?.toString() ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'^/+'), '')
        .replaceAll(RegExp(r'/+$'), '');
  }

  static String _lastSegment(String value) {
    final segments = value
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);
    return segments.isEmpty ? '' : segments.last;
  }

  static Map<String, Object?> _extractAttributes(Map<String, dynamic> claims) {
    final result = <String, Object?>{};
    for (final entry in claims.entries) {
      final key = entry.key.toLowerCase();
      if (key.startsWith('gorape_')) {
        result[key] = _firstValue(entry.value);
      }
    }
    for (final container in const ['attributes', 'user_attributes']) {
      for (final entry in _asMap(claims[container]).entries) {
        final key = entry.key.toString().toLowerCase();
        if (key.startsWith('gorape_')) {
          result[key] = _firstValue(entry.value);
        }
      }
    }
    return result;
  }

  static Object? _valueOf(
    Map<String, dynamic> claims,
    Map<String, Object?> attributes,
    List<String> names,
  ) {
    for (final name in names) {
      final attribute = attributes[name];
      if (attribute != null && attribute.toString().trim().isNotEmpty) {
        return attribute;
      }
      final claim = claims[name];
      if (claim != null && claim.toString().trim().isNotEmpty) return claim;
    }
    return null;
  }

  static Object? _firstValue(Object? value) {
    if (value is List) {
      final items = [
        for (final item in value)
          if (item != null && item.toString().trim().isNotEmpty) item,
      ];
      if (items.isEmpty) return null;
      // Preserve multi-valued attributes so the strongest role can win.
      return items.length == 1 ? items.first : items;
    }
    return value;
  }

  static List<String> _strings(Object? value) {
    if (value == null) return const [];
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? const [] : [trimmed];
    }
    if (value is Iterable) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return decoded.map((key, item) => MapEntry(key.toString(), item));
        }
      } on FormatException {
        // Ignore malformed JSON claims; role resolution falls back safely.
      }
    }
    return const {};
  }

  static List<String> _unique(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      if (value.isEmpty) continue;
      if (seen.add(value.toLowerCase())) result.add(value);
    }
    return result;
  }
}

extension ProjectAccessKeys on Project {
  Iterable<String> get accessKeys => [
    id,
    slug,
    name,
    keycloakRealm,
    oidcIssuer,
  ];
}

extension GroupAccessKeys on Group {
  Iterable<String> get accessKeys => [
    id,
    slug,
    name,
    '/$slug',
    '$projectId/$slug',
  ];
}
