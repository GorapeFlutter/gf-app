import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../api/gorape_api_client.dart';
import '../api/models/attestation.dart';
import '../api/models/device.dart';
import '../api/models/project.dart';
import '../core/config/connection_settings.dart';
import '../device_keys/device_key_provider.dart';
import '../device_keys/device_key_provider_factory.dart';
import '../device_keys/device_key_store.dart';
import '../device_keys/device_proof_service.dart';
import '../device_keys/device_registration_service.dart';
import '../platform/platform_support.dart';
import '../policy/device_policy.dart';
import 'auth_controller.dart';

final gorapeApiProvider = Provider<GorapeApi>((ref) {
  final platform = ref.watch(runtimePlatformProvider);
  final settings =
      ref.watch(connectionSettingsProvider).value ??
      ConnectionSettings.defaultsFromEnvironment(platform);
  final client = http.Client();
  ref.onDispose(client.close);
  return GorapeApiClient(
    baseUrl: settings.apiBaseUrl,
    httpClient: client,
    accessTokenProvider: ref.watch(accessTokenProvider),
    refreshAccessToken: () async {
      final auth = ref.read(authControllerProvider.notifier);
      final refreshed = await auth.refreshSession();
      if (!refreshed) {
        await auth.handleUnauthorized();
      }
      return refreshed;
    },
  );
});

final platformSupportProvider = Provider<PlatformSupport>((ref) {
  return PlatformSupport.forRuntime(ref.watch(runtimePlatformProvider));
});

final deviceKeyProvider = Provider<DeviceKeyProvider>((ref) {
  return createDeviceKeyProvider(ref.watch(runtimePlatformProvider));
});

final deviceKeyStoreProvider = Provider<DeviceKeyStore>((ref) {
  return DeviceKeyStore(ref.watch(secureStoreProvider));
});

final deviceKeyAvailabilityProvider = FutureProvider<DeviceKeyAvailability>((
  ref,
) {
  return ref.watch(deviceKeyProvider).availability();
});

final deviceRegistrationServiceProvider = Provider<DeviceRegistrationService>((
  ref,
) {
  return DeviceRegistrationService(
    api: ref.watch(gorapeApiProvider),
    keyProvider: ref.watch(deviceKeyProvider),
    keyStore: ref.watch(deviceKeyStoreProvider),
  );
});

final deviceProofServiceProvider = Provider<DeviceProofService>((ref) {
  return DeviceProofService(
    api: ref.watch(gorapeApiProvider),
    keyProvider: ref.watch(deviceKeyProvider),
    keyStore: ref.watch(deviceKeyStoreProvider),
  );
});

final devicePolicyRepositoryProvider = Provider<DevicePolicyRepository>((ref) {
  return DevicePolicyRepository(ref.watch(secureStoreProvider));
});

class ProjectsController extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    final session = await ref.watch(authControllerProvider.future);
    if (session == null) return const [];
    return ref.watch(gorapeApiProvider).listProjects();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = ref.read(authControllerProvider).value;
      if (session == null) return const [];
      return ref.read(gorapeApiProvider).listProjects();
    });
  }
}

final projectsProvider =
    AsyncNotifierProvider<ProjectsController, List<Project>>(
      ProjectsController.new,
    );

class SelectedProjectIdController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String projectId) => state = projectId;
}

final selectedProjectIdProvider =
    NotifierProvider<SelectedProjectIdController, String?>(
      SelectedProjectIdController.new,
    );

final selectedProjectProvider = Provider<Project?>((ref) {
  final projects = ref.watch(projectsProvider).value ?? const <Project>[];
  if (projects.isEmpty) return null;
  final selectedId = ref.watch(selectedProjectIdProvider);
  return projects.firstWhere(
    (project) => project.id == selectedId,
    orElse: () => projects.first,
  );
});

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

class DevicesController extends AsyncNotifier<List<Device>> {
  DevicesController(this.projectId);

  final String projectId;

  @override
  Future<List<Device>> build() async {
    final session = await ref.watch(authControllerProvider.future);
    if (session == null) return const [];
    return ref.watch(gorapeApiProvider).listDevices(projectId);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(gorapeApiProvider).listDevices(projectId),
    );
  }
}

final devicesProvider =
    AsyncNotifierProvider.family<DevicesController, List<Device>, String>(
      DevicesController.new,
    );

class CapabilitiesController extends AsyncNotifier<AttestationCapabilities> {
  CapabilitiesController(this.projectId);

  final String projectId;

  @override
  Future<AttestationCapabilities> build() async {
    final session = await ref.watch(authControllerProvider.future);
    if (session == null) return const AttestationCapabilities({});
    return ref.watch(gorapeApiProvider).attestationCapabilities(projectId);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(gorapeApiProvider).attestationCapabilities(projectId),
    );
  }
}

final capabilitiesProvider =
    AsyncNotifierProvider.family<
      CapabilitiesController,
      AttestationCapabilities,
      String
    >(CapabilitiesController.new);

class AttestationsController extends AsyncNotifier<List<AttestationRecord>> {
  AttestationsController(this.refKey);

  final DeviceRef refKey;

  @override
  Future<List<AttestationRecord>> build() async {
    final session = await ref.watch(authControllerProvider.future);
    if (session == null) return const [];
    return ref
        .watch(gorapeApiProvider)
        .attestations(refKey.projectId, refKey.deviceId);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(gorapeApiProvider)
          .attestations(refKey.projectId, refKey.deviceId),
    );
  }
}

final attestationsProvider =
    AsyncNotifierProvider.family<
      AttestationsController,
      List<AttestationRecord>,
      DeviceRef
    >(AttestationsController.new);

final localDeviceKeyProvider =
    FutureProvider.family<RegisteredDeviceKey?, DeviceRef>((ref, refKey) {
      return ref
          .watch(deviceKeyStoreProvider)
          .load(refKey.projectId, refKey.deviceId);
    });

final deviceDetailProvider = FutureProvider.family<Device, DeviceRef>((
  ref,
  refKey,
) {
  return ref
      .watch(gorapeApiProvider)
      .getDevice(refKey.projectId, refKey.deviceId);
});

class PolicyController extends AsyncNotifier<LocalDevicePolicy> {
  @override
  Future<LocalDevicePolicy> build() {
    return ref.watch(devicePolicyRepositoryProvider).load();
  }

  Future<void> save(LocalDevicePolicy value) async {
    await ref.read(devicePolicyRepositoryProvider).save(value);
    state = AsyncData(value);
  }
}

final policyControllerProvider =
    AsyncNotifierProvider<PolicyController, LocalDevicePolicy>(
      PolicyController.new,
    );

class DeviceActions {
  DeviceActions(this._ref);

  final Ref _ref;

  Future<RegistrationResult> register({
    required String projectId,
    required String displayName,
  }) async {
    final result = await _ref
        .read(deviceRegistrationServiceProvider)
        .register(projectId: projectId, displayName: displayName);
    _ref.invalidate(devicesProvider(projectId));
    _ref.invalidate(
      localDeviceKeyProvider(
        DeviceRef(projectId: projectId, deviceId: result.device.id),
      ),
    );
    return result;
  }

  Future<void> provePossession({
    required String projectId,
    required String deviceId,
  }) async {
    await _ref
        .read(deviceProofServiceProvider)
        .verifyPossession(projectId: projectId, deviceId: deviceId);
    _ref.invalidate(
      attestationsProvider(DeviceRef(projectId: projectId, deviceId: deviceId)),
    );
    _ref.invalidate(devicesProvider(projectId));
  }

  Future<void> revoke({
    required String projectId,
    required String deviceId,
  }) async {
    await _ref.read(gorapeApiProvider).revokeDevice(projectId, deviceId);
    await _ref
        .read(deviceRegistrationServiceProvider)
        .deleteLocalKey(projectId, deviceId);
    _ref.invalidate(devicesProvider(projectId));
    _ref.invalidate(
      attestationsProvider(DeviceRef(projectId: projectId, deviceId: deviceId)),
    );
    _ref.invalidate(
      localDeviceKeyProvider(
        DeviceRef(projectId: projectId, deviceId: deviceId),
      ),
    );
  }
}

final deviceActionsProvider = Provider<DeviceActions>(DeviceActions.new);
