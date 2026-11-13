class DeviceRef {
  const DeviceRef({required this.projectId, required this.deviceId});
  final String projectId;
  final String deviceId;

  @override
  bool operator ==(Object other) =>
      other is DeviceRef &&
      other.projectId == projectId &&
      other.deviceId == deviceId;

  @override
  int get hashCode => Object.hash(projectId, deviceId);
}
