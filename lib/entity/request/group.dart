/// Payload for `POST /v1/projects/{projectId}/groups`.
class GroupCreateRequest {
  const GroupCreateRequest({required this.slug, required this.name});

  final String slug;
  final String name;

  Map<String, dynamic> toJson() => {'slug': slug, 'name': name};
}

/// Payload for `PATCH /v1/projects/{projectId}/groups/{groupId}`.
class GroupUpdateRequest {
  const GroupUpdateRequest({required this.name, this.status = 'active'});

  final String name;
  final String status;

  Map<String, dynamic> toJson() => {'name': name, 'status': status};
}

/// Payload for project and group role binding endpoints.
class RoleCreateRequest {
  const RoleCreateRequest({required this.oidcSubject, required this.role});

  final String oidcSubject;
  final String role;

  Map<String, dynamic> toJson() => {'subject': oidcSubject, 'role': role};
}

/// Payload for `POST /v1/projects/{projectId}/groups/{groupId}/devices`.
class DeviceGroupCreateRequest {
  const DeviceGroupCreateRequest({required this.deviceId});

  final String deviceId;

  Map<String, dynamic> toJson() => {'device_id': deviceId};
}
