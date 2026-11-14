import '../entity/model/device.dart';
import '../entity/model/group.dart';
import '../entity/request/group.dart';
import '../repository/group.dart';

abstract interface class GroupUsecase {
  /// GF-01093 — Handles list in GroupUsecase.
  Future<List<Group>> list(String projectId);

  /// GF-01094 — Handles get in GroupUsecase.
  Future<Group> get(String projectId, String groupId);

  /// GF-01095 — Handles create in GroupUsecase.
  Future<Group> create(String projectId, GroupCreateRequest request);

  /// GF-01096 — Handles update in GroupUsecase.
  Future<Group> update(
    String projectId,
    String groupId,
    GroupUpdateRequest request,
  );

  /// GF-01097 — Handles delete in GroupUsecase.
  Future<void> delete(String projectId, String groupId);

  /// GF-01098 — Handles devices in GroupUsecase.
  Future<List<Device>> devices(String projectId, String groupId);

  /// GF-01099 — Handles bind device in GroupUsecase.
  Future<void> bindDevice(String projectId, String groupId, String deviceId);

  /// GF-01100 — Handles unbind device in GroupUsecase.
  Future<void> unbindDevice(String projectId, String groupId, String deviceId);
}

final class GroupUsecaseImpl implements GroupUsecase {
  /// GF-01101 — Initializes GroupUsecaseImpl.
  const GroupUsecaseImpl(this._repository);

  final GroupRepository _repository;

  /// GF-01102 — Handles list in GroupUsecaseImpl.
  @override
  Future<List<Group>> list(String projectId) => _repository.list(projectId);

  /// GF-01103 — Handles get in GroupUsecaseImpl.
  @override
  Future<Group> get(String projectId, String groupId) =>
      _repository.get(projectId, groupId);

  /// GF-01104 — Handles create in GroupUsecaseImpl.
  @override
  Future<Group> create(String projectId, GroupCreateRequest request) =>
      _repository.create(projectId, request);

  /// GF-01105 — Handles update in GroupUsecaseImpl.
  @override
  Future<Group> update(
    String projectId,
    String groupId,
    GroupUpdateRequest request,
  ) => _repository.update(projectId, groupId, request);

  /// GF-01106 — Handles delete in GroupUsecaseImpl.
  @override
  Future<void> delete(String projectId, String groupId) =>
      _repository.delete(projectId, groupId);

  /// GF-01107 — Handles devices in GroupUsecaseImpl.
  @override
  Future<List<Device>> devices(String projectId, String groupId) =>
      _repository.devices(projectId, groupId);

  /// GF-01108 — Handles bind device in GroupUsecaseImpl.
  @override
  Future<void> bindDevice(String projectId, String groupId, String deviceId) =>
      _repository.bindDevice(projectId, groupId, deviceId);

  /// GF-01109 — Handles unbind device in GroupUsecaseImpl.
  @override
  Future<void> unbindDevice(
    String projectId,
    String groupId,
    String deviceId,
  ) => _repository.unbindDevice(projectId, groupId, deviceId);
}

/// GF-01110 — Creates an instance for new group usecase.
GroupUsecase newGroupUsecase(GroupRepository repository) =>
    GroupUsecaseImpl(repository);
