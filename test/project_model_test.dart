import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/entity/model/project.dart';

void main() {
  group('Project.fromJson', () {
    test('uses realm from the API when present', () {
      final project = Project.fromJson({
        'id': 'project-1',
        'slug': 'demo',
        'name': 'Demo',
        'issuer': 'http://localhost:8080/realms/gorape',
        'realm': 'gorape',
      });

      expect(project.keycloakRealm, 'gorape');
    });

    test('derives realm from issuer when the API leaves it blank', () {
      final project = Project.fromJson({
        'id': 'project-1',
        'slug': 'demo',
        'name': 'Demo',
        'issuer': 'http://localhost:8080/realms/gorape',
        'realm': '',
      });

      expect(project.keycloakRealm, 'gorape');
    });
  });
}
