import '../entity/model/device.dart';
import '../entity/model/group.dart';
import '../entity/request/group.dart';
import 'gorape.dart';

abstract interface class GroupRepository {
  Future<List<Group>> list(String projectId);

  Future<Group> get(String projectId, String groupId);

  Future<Group> create(String projectId, GroupCreateRequest request);

  Future<Group> update(
    String projectId,
    String groupId,
    GroupUpdateRequest request,
  );

  Future<void> delete(String projectId, String groupId);

  Future<List<Device>> devices(String projectId, String groupId);

  Future<void> bindDevice(String projectId, String groupId, String deviceId);

  Future<void> unbindDevice(String projectId, String groupId, String deviceId);
}

final class GroupRepositoryImpl implements GroupRepository {
  const GroupRepositoryImpl(this._api);

  final GorapeApi _api;

  @override
  Future<List<Group>> list(String projectId) => _api.listGroups(projectId);

  @override
  Future<Group> get(String projectId, String groupId) =>
      _api.getGroup(projectId, groupId);

  @override
  Future<Group> create(String projectId, GroupCreateRequest request) =>
      _api.createGroup(projectId, request);

  @override
  Future<Group> update(
    String projectId,
    String groupId,
    GroupUpdateRequest request,
  ) => _api.updateGroup(projectId, groupId, request);

  @override
  Future<void> delete(String projectId, String groupId) =>
      _api.deleteGroup(projectId, groupId);

  @override
  Future<List<Device>> devices(String projectId, String groupId) =>
      _api.listGroupDevices(projectId, groupId);

  @override
  Future<void> bindDevice(String projectId, String groupId, String deviceId) =>
      _api.bindDeviceToGroup(projectId, groupId, deviceId);

  @override
  Future<void> unbindDevice(
    String projectId,
    String groupId,
    String deviceId,
  ) => _api.unbindDeviceFromGroup(projectId, groupId, deviceId);
}

GroupRepository newGroupRepository(GorapeApi api) => GroupRepositoryImpl(api);
