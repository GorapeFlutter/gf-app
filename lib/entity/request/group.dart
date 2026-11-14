/// Payload for `POST /v1/projects/{projectId}/groups`.
class GroupCreateRequest {
  /// GF-00379 — Initializes GroupCreateRequest.
  const GroupCreateRequest({required this.slug, required this.name});

  final String slug;
  final String name;

  /// GF-00380 — Serializes data in GroupCreateRequest.
  Map<String, dynamic> toJson() => {'slug': slug, 'name': name};
}

/// Payload for `PATCH /v1/projects/{projectId}/groups/{groupId}`.
class GroupUpdateRequest {
  /// GF-00381 — Initializes GroupUpdateRequest.
  const GroupUpdateRequest({required this.name, this.status = 'active'});

  final String name;
  final String status;

  /// GF-00382 — Serializes data in GroupUpdateRequest.
  Map<String, dynamic> toJson() => {'name': name, 'status': status};
}

/// Payload for project and group role binding endpoints.
class RoleCreateRequest {
  /// GF-00383 — Initializes RoleCreateRequest.
  const RoleCreateRequest({required this.oidcSubject, required this.role});

  final String oidcSubject;
  final String role;

  /// GF-00384 — Serializes data in RoleCreateRequest.
  Map<String, dynamic> toJson() => {'subject': oidcSubject, 'role': role};
}

/// Payload for `POST /v1/projects/{projectId}/groups/{groupId}/devices`.
class DeviceGroupCreateRequest {
  /// GF-00385 — Initializes DeviceGroupCreateRequest.
  const DeviceGroupCreateRequest({required this.deviceId});

  final String deviceId;

  /// GF-00386 — Serializes data in DeviceGroupCreateRequest.
  Map<String, dynamic> toJson() => {'device_id': deviceId};
}
