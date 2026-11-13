/// A Gorape project returned by `GET /v1/projects`.
class Project {
  const Project({
    required this.id,
    required this.slug,
    required this.name,
    required this.oidcIssuer,
    this.keycloakRealm = '',
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String slug;
  final String name;
  final String oidcIssuer;
  final String keycloakRealm;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == 'active';

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: _string(json['id']),
      slug: _string(json['slug']),
      name: _string(json['name']),
      oidcIssuer: _string(json['oidc_issuer']),
      keycloakRealm: _string(json['keycloak_realm']),
      status: _string(json['status'], fallback: 'active'),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'name': name,
    'oidc_issuer': oidcIssuer,
    'keycloak_realm': keycloakRealm,
    'status': status,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  static String _string(Object? value, {String fallback = ''}) =>
      value is String ? value : fallback;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
