import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entity/model/device.dart';
import '../entity/model/device_key.dart';
import '../entity/model/device_ref.dart';
import '../entity/model/registered_device_key.dart';
import '../entity/response/device.dart';
import 'attestation.dart';
import 'auth.dart';
import 'dependencies.dart';

abstract interface class DevicesController {
  Future<void> reload();
}

final class DevicesControllerImpl extends AsyncNotifier<List<Device>>
    implements DevicesController {
  DevicesControllerImpl(this.projectId);
  final String projectId;

  @override
  Future<List<Device>> build() async {
    if (!ref.watch(isAuthenticatedProvider)) return const [];
    return ref.watch(deviceUsecaseProvider).list(projectId);
  }

  @override
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(deviceUsecaseProvider).list(projectId),
    );
  }
}

final devicesProvider =
    AsyncNotifierProvider.family<DevicesControllerImpl, List<Device>, String>(
      DevicesControllerImpl.new,
    );

final deviceDetailProvider = FutureProvider.family<Device, DeviceRef>(
  (ref, key) =>
      ref.watch(deviceUsecaseProvider).get(key.projectId, key.deviceId),
);

final localDeviceKeyProvider =
    FutureProvider.family<RegisteredDeviceKey?, DeviceRef>(
      (ref, key) => ref
          .watch(deviceUsecaseProvider)
          .localKey(key.projectId, key.deviceId),
    );

final deviceKeyAvailabilityProvider = FutureProvider<DeviceKeyAvailability>(
  (ref) => ref.watch(deviceUsecaseProvider).availability(),
);

final devicePlatformProvider = Provider<String>(
  (ref) => ref.watch(deviceUsecaseProvider).platform,
);

abstract interface class DeviceController {
  Future<RegistrationResult> register({
    required String projectId,
    required String displayName,
  });
  Future<void> provePossession({
    required String projectId,
    required String deviceId,
  });
  Future<void> revoke({required String projectId, required String deviceId});
}

final class DeviceControllerImpl implements DeviceController {
  DeviceControllerImpl(this._ref);
  final Ref _ref;

  @override
  Future<RegistrationResult> register({
    required String projectId,
    required String displayName,
  }) async {
    final result = await _ref
        .read(deviceUsecaseProvider)
        .register(projectId: projectId, displayName: displayName);
    _ref.invalidate(devicesProvider(projectId));
    _ref.invalidate(
      localDeviceKeyProvider(
        DeviceRef(projectId: projectId, deviceId: result.device.id),
      ),
    );
    return result;
  }

  @override
  Future<void> provePossession({
    required String projectId,
    required String deviceId,
  }) async {
    await _ref
        .read(deviceUsecaseProvider)
        .provePossession(projectId: projectId, deviceId: deviceId);
    _ref.invalidate(
      attestationsProvider(DeviceRef(projectId: projectId, deviceId: deviceId)),
    );
    _ref.invalidate(devicesProvider(projectId));
  }

  @override
  Future<void> revoke({
    required String projectId,
    required String deviceId,
  }) async {
    await _ref
        .read(deviceUsecaseProvider)
        .revoke(projectId: projectId, deviceId: deviceId);
    final key = DeviceRef(projectId: projectId, deviceId: deviceId);
    _ref.invalidate(devicesProvider(projectId));
    _ref.invalidate(attestationsProvider(key));
    _ref.invalidate(localDeviceKeyProvider(key));
  }
}

DeviceController newDeviceController(Ref ref) => DeviceControllerImpl(ref);

final deviceControllerProvider = Provider<DeviceController>(
  newDeviceController,
);
