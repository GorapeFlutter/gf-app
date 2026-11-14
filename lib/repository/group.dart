import '../entity/model/device.dart';
import '../entity/model/group.dart';
import '../entity/request/group.dart';
import 'gorape.dart';

abstract interface class GroupRepository {
  /// GF-00559 — Handles list in GroupRepository.
  Future<List<Group>> list(String projectId);

  /// GF-00560 — Handles get in GroupRepository.
  Future<Group> get(String projectId, String groupId);

  /// GF-00561 — Handles create in GroupRepository.
  Future<Group> create(String projectId, GroupCreateRequest request);

  /// GF-00562 — Handles update in GroupRepository.
  Future<Group> update(
    String projectId,
    String groupId,
    GroupUpdateRequest request,
  );

  /// GF-00563 — Handles delete in GroupRepository.
  Future<void> delete(String projectId, String groupId);

  /// GF-00564 — Handles devices in GroupRepository.
  Future<List<Device>> devices(String projectId, String groupId);

  /// GF-00565 — Handles bind device in GroupRepository.
  Future<void> bindDevice(String projectId, String groupId, String deviceId);

  /// GF-00566 — Handles unbind device in GroupRepository.
  Future<void> unbindDevice(String projectId, String groupId, String deviceId);
}

final class GroupRepositoryImpl implements GroupRepository {
  /// GF-00567 — Initializes GroupRepositoryImpl.
  const GroupRepositoryImpl(this._api);

  final GorapeApi _api;

  /// GF-00568 — Handles list in GroupRepositoryImpl.
  @override
  Future<List<Group>> list(String projectId) => _api.listGroups(projectId);

  /// GF-00569 — Handles get in GroupRepositoryImpl.
  @override
  Future<Group> get(String projectId, String groupId) =>
      _api.getGroup(projectId, groupId);

  /// GF-00570 — Handles create in GroupRepositoryImpl.
  @override
  Future<Group> create(String projectId, GroupCreateRequest request) =>
      _api.createGroup(projectId, request);

  /// GF-00571 — Handles update in GroupRepositoryImpl.
  @override
  Future<Group> update(
    String projectId,
    String groupId,
    GroupUpdateRequest request,
  ) => _api.updateGroup(projectId, groupId, request);

  /// GF-00572 — Handles delete in GroupRepositoryImpl.
  @override
  Future<void> delete(String projectId, String groupId) =>
      _api.deleteGroup(projectId, groupId);

  /// GF-00573 — Handles devices in GroupRepositoryImpl.
  @override
  Future<List<Device>> devices(String projectId, String groupId) =>
      _api.listGroupDevices(projectId, groupId);

  /// GF-00574 — Handles bind device in GroupRepositoryImpl.
  @override
  Future<void> bindDevice(String projectId, String groupId, String deviceId) =>
      _api.bindDeviceToGroup(projectId, groupId, deviceId);

  /// GF-00575 — Handles unbind device in GroupRepositoryImpl.
  @override
  Future<void> unbindDevice(
    String projectId,
    String groupId,
    String deviceId,
  ) => _api.unbindDeviceFromGroup(projectId, groupId, deviceId);
}

/// GF-00576 — Creates an instance for new group repository.
GroupRepository newGroupRepository(GorapeApi api) => GroupRepositoryImpl(api);
