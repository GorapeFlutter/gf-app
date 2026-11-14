import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entity/model/device.dart';
import '../entity/model/group.dart';
import '../entity/request/group.dart';
import 'auth.dart';
import 'dependencies.dart';

abstract interface class GroupsController {
  /// GF-00198 — Handles reload in GroupsController.
  Future<void> reload();
}

/// GF-00004 — Loads the groups visible in the selected project.
final class GroupsControllerImpl extends AsyncNotifier<List<Group>>
    implements GroupsController {
  /// GF-00199 — Initializes GroupsControllerImpl.
  GroupsControllerImpl(this.projectId);

  final String projectId;

  /// GF-00200 — Builds the widget or value for GroupsControllerImpl.
  @override
  Future<List<Group>> build() async {
    if (!ref.watch(isAuthenticatedProvider)) return const [];
    return ref.watch(groupUsecaseProvider).list(projectId);
  }

  /// GF-00201 — Handles reload in GroupsControllerImpl.
  @override
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      /* GF-00202 — Runs an inline callback in GroupsControllerImpl.reload. */ () =>
          ref.read(groupUsecaseProvider).list(projectId),
    );
  }
}

final groupsProvider =
    AsyncNotifierProvider.family<GroupsControllerImpl, List<Group>, String>(
      GroupsControllerImpl.new,
    );

final groupDevicesProvider = FutureProvider.family<List<Device>, GroupRef>(
  /* GF-00203 — Runs an inline callback in top level. */ (ref, key) =>
      ref.watch(groupUsecaseProvider).devices(key.projectId, key.groupId),
);

abstract interface class GroupController {
  /// GF-00204 — Handles create in GroupController.
  Future<Group> create(String projectId, GroupCreateRequest request);

  /// GF-00205 — Handles update in GroupController.
  Future<Group> update(
    String projectId,
    String groupId,
    GroupUpdateRequest request,
  );

  /// GF-00206 — Handles delete in GroupController.
  Future<void> delete(String projectId, String groupId);

  /// GF-00207 — Handles bind device in GroupController.
  Future<void> bindDevice(String projectId, String groupId, String deviceId);

  /// GF-00208 — Handles unbind device in GroupController.
  Future<void> unbindDevice(String projectId, String groupId, String deviceId);
}

/// GF-00008 — Applies group and device-membership changes, then invalidates data.
final class GroupControllerImpl implements GroupController {
  /// GF-00209 — Initializes GroupControllerImpl.
  GroupControllerImpl(this._ref);

  final Ref _ref;

  /// GF-00210 — Handles create in GroupControllerImpl.
  @override
  Future<Group> create(String projectId, GroupCreateRequest request) async {
    // GF-02048 — Create the group through the application use case.
    final group = await _ref
        .read(groupUsecaseProvider)
        .create(projectId, request);
    // GF-02049 — Refresh the project's group list after creation.
    _ref.invalidate(groupsProvider(projectId));
    return group;
  }

  /// GF-00211 — Handles update in GroupControllerImpl.
  @override
  Future<Group> update(
    String projectId,
    String groupId,
    GroupUpdateRequest request,
  ) async {
    // GF-02050 — Persist the edited group through the application use case.
    final group = await _ref
        .read(groupUsecaseProvider)
        .update(projectId, groupId, request);
    // GF-02051 — Refresh the project's group list after editing.
    _ref.invalidate(groupsProvider(projectId));
    return group;
  }

  /// GF-00212 — Handles delete in GroupControllerImpl.
  @override
  Future<void> delete(String projectId, String groupId) async {
    // GF-02052 — Delete the group on the backend.
    await _ref.read(groupUsecaseProvider).delete(projectId, groupId);
    // GF-02053 — Invalidate the group and its membership data.
    _ref.invalidate(groupsProvider(projectId));
    _ref.invalidate(
      groupDevicesProvider(GroupRef(projectId: projectId, groupId: groupId)),
    );
  }

  /// GF-00213 — Handles bind device in GroupControllerImpl.
  @override
  Future<void> bindDevice(
    String projectId,
    String groupId,
    String deviceId,
  ) async {
    // GF-02054 — Add the device to the backend group membership.
    await _ref
        .read(groupUsecaseProvider)
        .bindDevice(projectId, groupId, deviceId);
    // GF-02055 — Reload the membership list after assignment.
    _ref.invalidate(
      groupDevicesProvider(GroupRef(projectId: projectId, groupId: groupId)),
    );
  }

  /// GF-00214 — Handles unbind device in GroupControllerImpl.
  @override
  Future<void> unbindDevice(
    String projectId,
    String groupId,
    String deviceId,
  ) async {
    // GF-02056 — Remove the device from the backend group membership.
    await _ref
        .read(groupUsecaseProvider)
        .unbindDevice(projectId, groupId, deviceId);
    // GF-02057 — Reload the membership list after removal.
    _ref.invalidate(
      groupDevicesProvider(GroupRef(projectId: projectId, groupId: groupId)),
    );
  }
}

final groupControllerProvider = Provider<GroupController>(
  GroupControllerImpl.new,
);
