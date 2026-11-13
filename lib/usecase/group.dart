import '../entity/model/device.dart';
import '../entity/model/group.dart';
import '../entity/request/group.dart';
import '../repository/group.dart';

abstract interface class GroupUsecase {
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

final class GroupUsecaseImpl implements GroupUsecase {
  const GroupUsecaseImpl(this._repository);

  final GroupRepository _repository;

  @override
  Future<List<Group>> list(String projectId) => _repository.list(projectId);

  @override
  Future<Group> get(String projectId, String groupId) =>
      _repository.get(projectId, groupId);

  @override
  Future<Group> create(String projectId, GroupCreateRequest request) =>
      _repository.create(projectId, request);

  @override
  Future<Group> update(
    String projectId,
    String groupId,
    GroupUpdateRequest request,
  ) => _repository.update(projectId, groupId, request);

  @override
  Future<void> delete(String projectId, String groupId) =>
      _repository.delete(projectId, groupId);

  @override
  Future<List<Device>> devices(String projectId, String groupId) =>
      _repository.devices(projectId, groupId);

  @override
  Future<void> bindDevice(String projectId, String groupId, String deviceId) =>
      _repository.bindDevice(projectId, groupId, deviceId);

  @override
  Future<void> unbindDevice(
    String projectId,
    String groupId,
    String deviceId,
  ) => _repository.unbindDevice(projectId, groupId, deviceId);
}

GroupUsecase newGroupUsecase(GroupRepository repository) =>
    GroupUsecaseImpl(repository);
