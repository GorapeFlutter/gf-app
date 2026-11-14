class DeviceRef {
  /// GF-00289 — Initializes DeviceRef.
  const DeviceRef({required this.projectId, required this.deviceId});
  final String projectId;
  final String deviceId;

  /// GF-00290 — Handles == in DeviceRef.
  @override
  bool operator ==(Object other) =>
      other is DeviceRef &&
      other.projectId == projectId &&
      other.deviceId == deviceId;

  /// GF-00291 — Computes DeviceRef.hashCode.
  @override
  int get hashCode => Object.hash(projectId, deviceId);
}
