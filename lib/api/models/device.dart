/// A device returned by the Gorape device endpoints.
class Device {
  const Device({
    required this.id,
    required this.projectId,
    required this.ownerPrincipalId,
    required this.platform,
    required this.displayName,
    required this.status,
    required this.registeredAt,
    this.lastVerifiedAt,
    this.revokedAt,
    this.version = 1,
  });

  final String id;
  final String projectId;
  final String ownerPrincipalId;
  final String platform;
  final String displayName;
  final String status;
  final DateTime registeredAt;
  final DateTime? lastVerifiedAt;
  final DateTime? revokedAt;
  final int version;

  bool get isActive => status == 'active';

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: _string(json['id']),
      projectId: _string(json['project_id']),
      ownerPrincipalId: _string(json['owner_principal_id']),
      platform: _string(json['platform']),
      displayName: _string(json['display_name']),
      status: _string(json['status'], fallback: 'active'),
      registeredAt:
          _date(json['registered_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastVerifiedAt: _date(json['last_verified_at']),
      revokedAt: _date(json['revoked_at']),
      version: _int(json['version']),
    );
  }

  static String _string(Object? value, {String fallback = ''}) =>
      value is String ? value : fallback;

  static int _int(Object? value) =>
      value is int ? value : int.tryParse('$value') ?? 1;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
