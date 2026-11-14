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
  /// GF-00181 — Handles reload in DevicesController.
  Future<void> reload();
}

/// GF-00004 — Loads a project's device list through the device use case.
final class DevicesControllerImpl extends AsyncNotifier<List<Device>>
    implements DevicesController {
  /// GF-00182 — Initializes DevicesControllerImpl.
  DevicesControllerImpl(this.projectId);
  final String projectId;

  /// GF-00183 — Builds the widget or value for DevicesControllerImpl.
  @override
  Future<List<Device>> build() async {
    if (!ref.watch(isAuthenticatedProvider)) return const [];
    return ref.watch(deviceUsecaseProvider).list(projectId);
  }

  /// GF-00184 — Handles reload in DevicesControllerImpl.
  @override
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      /* GF-00185 — Runs an inline callback in DevicesControllerImpl.reload. */ () =>
          ref.read(deviceUsecaseProvider).list(projectId),
    );
  }
}

final devicesProvider =
    AsyncNotifierProvider.family<DevicesControllerImpl, List<Device>, String>(
      DevicesControllerImpl.new,
    );

final deviceDetailProvider = FutureProvider.family<Device, DeviceRef>(
  /* GF-00186 — Runs an inline callback in top level. */ (ref, key) =>
      ref.watch(deviceUsecaseProvider).get(key.projectId, key.deviceId),
);

final localDeviceKeyProvider =
    FutureProvider.family<RegisteredDeviceKey?, DeviceRef>(
      /* GF-00187 — Runs an inline callback in top level. */ (ref, key) => ref
          .watch(deviceUsecaseProvider)
          .localKey(key.projectId, key.deviceId),
    );

final deviceKeyAvailabilityProvider = FutureProvider<DeviceKeyAvailability>(
  /* GF-00188 — Runs an inline callback in top level. */ (ref) =>
      ref.watch(deviceUsecaseProvider).availability(),
);

final devicePlatformProvider = Provider<String>(
  /* GF-00189 — Runs an inline callback in top level. */ (ref) =>
      ref.watch(deviceUsecaseProvider).platform,
);

abstract interface class DeviceController {
  /// GF-00190 — Handles register in DeviceController.
  Future<RegistrationResult> register({
    required String projectId,
    required String displayName,
  });

  /// GF-00191 — Handles prove possession in DeviceController.
  Future<void> provePossession({
    required String projectId,
    required String deviceId,
  });

  /// GF-00192 — Handles revoke in DeviceController.
  Future<void> revoke({required String projectId, required String deviceId});
}

final class DeviceControllerImpl implements DeviceController {
  /// GF-00193 — Initializes DeviceControllerImpl.
  DeviceControllerImpl(this._ref);
  final Ref _ref;

  /// GF-00194 — Handles register in DeviceControllerImpl.
  /// GF-00005 — Delegates registration and refreshes device-related providers.
  @override
  Future<RegistrationResult> register({
    required String projectId,
    required String displayName,
  }) async {
    // GF-02042 — Run the registration use case and retain its result.
    final result = await _ref
        .read(deviceUsecaseProvider)
        .register(projectId: projectId, displayName: displayName);
    // GF-02043 — Refresh the project device list and local key view.
    _ref.invalidate(devicesProvider(projectId));
    _ref.invalidate(
      localDeviceKeyProvider(
        DeviceRef(projectId: projectId, deviceId: result.device.id),
      ),
    );
    return result;
  }

  /// GF-00195 — Handles prove possession in DeviceControllerImpl.
  /// GF-00006 — Delegates possession proof and refreshes the resulting data.
  @override
  Future<void> provePossession({
    required String projectId,
    required String deviceId,
  }) async {
    // GF-02044 — Complete proof verification through the device use case.
    await _ref
        .read(deviceUsecaseProvider)
        .provePossession(projectId: projectId, deviceId: deviceId);
    // GF-02045 — Refresh attestation history and device verification status.
    _ref.invalidate(
      attestationsProvider(DeviceRef(projectId: projectId, deviceId: deviceId)),
    );
    _ref.invalidate(devicesProvider(projectId));
  }

  /// GF-00196 — Handles revoke in DeviceControllerImpl.
  /// GF-00007 — Revokes a device and refreshes its dependent providers.
  @override
  Future<void> revoke({
    required String projectId,
    required String deviceId,
  }) async {
    // GF-02046 — Revoke the device and let the use case clean up local keys.
    await _ref
        .read(deviceUsecaseProvider)
        .revoke(projectId: projectId, deviceId: deviceId);
    // GF-02047 — Invalidate every provider that exposes revoked-device data.
    final key = DeviceRef(projectId: projectId, deviceId: deviceId);
    _ref.invalidate(devicesProvider(projectId));
    _ref.invalidate(attestationsProvider(key));
    _ref.invalidate(localDeviceKeyProvider(key));
  }
}

/// GF-00197 — Creates an instance for new device controller.
DeviceController newDeviceController(Ref ref) => DeviceControllerImpl(ref);

final deviceControllerProvider = Provider<DeviceController>(
  newDeviceController,
);
