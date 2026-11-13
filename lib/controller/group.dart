import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entity/model/device.dart';
import '../entity/model/group.dart';
import '../entity/request/group.dart';
import 'auth.dart';
import 'dependencies.dart';

abstract interface class GroupsController {
  Future<void> reload();
}

final class GroupsControllerImpl extends AsyncNotifier<List<Group>>
    implements GroupsController {
  GroupsControllerImpl(this.projectId);

  final String projectId;

  @override
  Future<List<Group>> build() async {
    if (!ref.watch(isAuthenticatedProvider)) return const [];
    return ref.watch(groupUsecaseProvider).list(projectId);
  }

  @override
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(groupUsecaseProvider).list(projectId),
    );
  }
}

final groupsProvider =
    AsyncNotifierProvider.family<GroupsControllerImpl, List<Group>, String>(
      GroupsControllerImpl.new,
    );

final groupDevicesProvider = FutureProvider.family<List<Device>, GroupRef>(
  (ref, key) =>
      ref.watch(groupUsecaseProvider).devices(key.projectId, key.groupId),
);

abstract interface class GroupController {
  Future<Group> create(String projectId, GroupCreateRequest request);

  Future<Group> update(
    String projectId,
    String groupId,
    GroupUpdateRequest request,
  );

  Future<void> delete(String projectId, String groupId);

  Future<void> bindDevice(String projectId, String groupId, String deviceId);

  Future<void> unbindDevice(String projectId, String groupId, String deviceId);
}

final class GroupControllerImpl implements GroupController {
  GroupControllerImpl(this._ref);

  final Ref _ref;

  @override
  Future<Group> create(String projectId, GroupCreateRequest request) async {
    final group = await _ref
        .read(groupUsecaseProvider)
        .create(projectId, request);
    _ref.invalidate(groupsProvider(projectId));
    return group;
  }

  @override
  Future<Group> update(
    String projectId,
    String groupId,
    GroupUpdateRequest request,
  ) async {
    final group = await _ref
        .read(groupUsecaseProvider)
        .update(projectId, groupId, request);
    _ref.invalidate(groupsProvider(projectId));
    return group;
  }

  @override
  Future<void> delete(String projectId, String groupId) async {
    await _ref.read(groupUsecaseProvider).delete(projectId, groupId);
    _ref.invalidate(groupsProvider(projectId));
    _ref.invalidate(
      groupDevicesProvider(GroupRef(projectId: projectId, groupId: groupId)),
    );
  }

  @override
  Future<void> bindDevice(
    String projectId,
    String groupId,
    String deviceId,
  ) async {
    await _ref
        .read(groupUsecaseProvider)
        .bindDevice(projectId, groupId, deviceId);
    _ref.invalidate(
      groupDevicesProvider(GroupRef(projectId: projectId, groupId: groupId)),
    );
  }

  @override
  Future<void> unbindDevice(
    String projectId,
    String groupId,
    String deviceId,
  ) async {
    await _ref
        .read(groupUsecaseProvider)
        .unbindDevice(projectId, groupId, deviceId);
    _ref.invalidate(
      groupDevicesProvider(GroupRef(projectId: projectId, groupId: groupId)),
    );
  }
}

final groupControllerProvider = Provider<GroupController>(
  GroupControllerImpl.new,
);
