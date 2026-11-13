import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/entity/model/group.dart';
import 'package:gf_app/entity/model/project.dart';
import 'package:gf_app/entity/model/role.dart';

Project _project({
  String id = 'project-1',
  String slug = 'gorape',
  String name = 'Gorape',
}) {
  return Project(
    id: id,
    slug: slug,
    name: name,
    oidcIssuer: 'http://localhost:8080/realms/gorape',
    keycloakRealm: 'gorape',
  );
}

Group _group({String slug = 'group001', String id = 'group-id-1'}) {
  return Group(
    id: id,
    projectId: 'project-1',
    slug: slug,
    name: slug.toUpperCase(),
  );
}

void main() {
  group('AccessRole', () {
    test('ranks roles admin > editor > viewer > none', () {
      expect(AccessRole.admin.atLeast(AccessRole.viewer), isTrue);
      expect(AccessRole.editor.canEdit, isTrue);
      expect(AccessRole.editor.canAdmin, isFalse);
      expect(AccessRole.viewer.canView, isTrue);
      expect(AccessRole.viewer.canEdit, isFalse);
      expect(AccessRole.none.canView, isFalse);
    });

    test('maps Keycloak role names, including group owners', () {
      expect(AccessRole.fromName('admin'), AccessRole.admin);
      expect(AccessRole.fromName('Owner'), AccessRole.admin);
      expect(AccessRole.fromName(['editor']), AccessRole.editor);
      expect(
        AccessRole.fromName(['viewer', 'admin']),
        AccessRole.admin,
        reason: 'multi-valued attributes resolve to the strongest role',
      );
      expect(AccessRole.fromName('app'), AccessRole.viewer);
      expect(AccessRole.fromName('read-only'), AccessRole.viewer);
      expect(AccessRole.fromName('unknown'), isNull);
      expect(AccessRole.fromName(null), isNull);
    });
  });

  group('RoleSnapshot', () {
    test('treats the "app" realm role as viewer', () {
      final snapshot = RoleSnapshot.fromClaims({
        'realm_access': {
          'roles': ['app'],
        },
      });

      expect(snapshot.clusterRole, AccessRole.viewer);
      expect(snapshot.projectRoleFor(_project().accessKeys), AccessRole.viewer);
    });

    test('prefers the strongest realm role', () {
      final snapshot = RoleSnapshot.fromClaims({
        'realm_access': {
          'roles': ['app', 'editor'],
        },
      });

      expect(snapshot.clusterRole, AccessRole.editor);
    });

    test('reads client roles from resource_access', () {
      final snapshot = RoleSnapshot.fromClaims({
        'resource_access': {
          'gorape-client': {
            'roles': ['admin'],
          },
        },
      });

      expect(snapshot.clientRoles, ['admin']);
      expect(snapshot.clusterRole, AccessRole.admin);
    });

    test('resolves per-project roles from gorape_project_<slug>_role', () {
      final snapshot = RoleSnapshot.fromClaims({
        'realm_access': {
          'roles': ['app'],
        },
        'gorape_project_gorape_role': ['editor'],
      });

      final project = _project();
      expect(snapshot.projectRoleFor(project.accessKeys), AccessRole.editor);
    });

    test('resolves project roles from a JSON claim map', () {
      final snapshot = RoleSnapshot.fromClaims({
        'realm_access': {
          'roles': ['app'],
        },
        'gorape_project_roles':
            '{"project-1":"admin","other-project":"viewer"}',
      });

      expect(snapshot.projectRoleFor(_project().accessKeys), AccessRole.admin);
    });

    test('resolves group roles from per-group user attributes', () {
      final snapshot = RoleSnapshot.fromClaims({
        'realm_access': {
          'roles': ['app'],
        },
        'gorape_group_group001_role': ['owner'],
      });

      final group = _group();
      expect(
        snapshot.groupRoleFor(group.accessKeys, projectRole: AccessRole.viewer),
        AccessRole.admin,
      );
    });

    test('uses the strongest value of a multi-valued attribute', () {
      final snapshot = RoleSnapshot.fromClaims({
        'gorape_group_group001_role': ['viewer', 'owner'],
      });

      expect(snapshot.groupRoleFor(_group().accessKeys), AccessRole.admin);
    });

    test('resolves group roles from role-suffixed group paths', () {
      final snapshot = RoleSnapshot.fromClaims({
        'groups': ['/group002/editor', '/group003/viewer'],
      });

      expect(snapshot.groupPaths, ['/group002/editor', '/group003/viewer']);
      expect(
        snapshot.groupRoleFor(_group(slug: 'group002').accessKeys),
        AccessRole.editor,
      );
      expect(
        snapshot.groupRoleFor(_group(slug: 'group003').accessKeys),
        AccessRole.viewer,
      );
    });

    test('resolves Gorape project and group roles from Keycloak paths', () {
      final snapshot = RoleSnapshot.fromClaims({
        'groups': [
          '/gorape/projects/gorape/roles/editor',
          '/gorape/projects/gorape/groups/group001/roles/admin',
        ],
      });

      final project = _project();
      final group = _group();
      final projectRole = snapshot.projectRoleFor(project.accessKeys);

      expect(projectRole, AccessRole.editor);
      expect(
        snapshot.groupRoleFor(group.accessKeys, projectRole: projectRole),
        AccessRole.admin,
      );
    });

    test('falls back to the project role for unassigned groups', () {
      final snapshot = RoleSnapshot.fromClaims({
        'realm_access': {
          'roles': ['editor'],
        },
      });

      final projectRole = snapshot.projectRoleFor(_project().accessKeys);
      expect(
        snapshot.groupRoleFor(_group().accessKeys, projectRole: projectRole),
        AccessRole.editor,
        reason: 'realm editor applies project-wide, so it wins for groups too',
      );
    });

    test('exposes plain group membership without implying a role', () {
      final snapshot = RoleSnapshot.fromClaims({
        'groups': ['/group001'],
      });

      expect(snapshot.groupPaths, ['/group001']);
      expect(snapshot.groupRoles, isEmpty);
      expect(snapshot.groupRoleFor(['/group001']), AccessRole.none);
    });

    test('supports the gorape_group_roles JSON claim', () {
      final snapshot = RoleSnapshot.fromClaims({
        'gorape_group_roles': '{"group001":"editor"}',
      });

      expect(snapshot.groupRoleFor(_group().accessKeys), AccessRole.editor);
    });

    test('returns none for an empty token', () {
      final snapshot = RoleSnapshot.fromClaims(const {});
      expect(snapshot.clusterRole, AccessRole.none);
      expect(snapshot.projectRoleFor(_project().accessKeys), AccessRole.none);
      expect(snapshot.allRoles, isEmpty);
    });
  });
}
