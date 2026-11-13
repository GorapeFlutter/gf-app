import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../repository/attestation.dart';
import '../repository/connection.dart';
import '../repository/device.dart';
import '../repository/device_key.dart';
import '../repository/gorape.dart';
import '../repository/group.dart';
import '../repository/policy.dart';
import '../repository/project.dart';
import '../repository/role.dart';
import '../usecase/attestation.dart';
import '../usecase/connection.dart';
import '../usecase/device.dart';
import '../usecase/group.dart';
import '../usecase/policy.dart';
import '../usecase/project.dart';
import '../usecase/role.dart';
import 'auth.dart';
import 'base.dart';
import 'connection.dart';

final gorapeApiProvider = Provider<GorapeApi>((ref) {
  final platform = ref.watch(runtimePlatformProvider);
  final settings =
      ref.watch(connectionSettingsProvider).value ??
      ref.watch(connectionConfigProvider).defaultsFromEnvironment(platform);
  final client = http.Client();
  ref.onDispose(client.close);
  return newGorapeApi(
    baseUrl: settings.apiBaseUrl,
    httpClient: client,
    accessTokenProvider: ref.watch(accessTokenProvider),
    refreshAccessToken: () async {
      final auth = ref.read(authControllerProvider.notifier);
      final refreshed = await auth.refreshSession();
      if (!refreshed) await auth.handleUnauthorized();
      return refreshed;
    },
  );
});

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => newProjectRepository(ref.watch(gorapeApiProvider)),
);
final projectUsecaseProvider = Provider<ProjectUsecase>(
  (ref) => newProjectUsecase(ref.watch(projectRepositoryProvider)),
);

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => newDeviceRepository(ref.watch(gorapeApiProvider)),
);
final attestationRepositoryProvider = Provider<AttestationRepository>(
  (ref) => newAttestationRepository(ref.watch(gorapeApiProvider)),
);
final attestationUsecaseProvider = Provider<AttestationUsecase>(
  (ref) => newAttestationUsecase(ref.watch(attestationRepositoryProvider)),
);

final deviceKeyRepositoryProvider = Provider<DeviceKeyRepository>(
  (ref) => newDeviceKeyRepository(ref.watch(runtimePlatformProvider)),
);
final deviceKeyStoreRepositoryProvider = Provider<DeviceKeyStoreRepository>(
  (ref) => newDeviceKeyStoreRepository(ref.watch(secureStoreProvider)),
);
final deviceUsecaseProvider = Provider<DeviceUsecase>(
  (ref) => newDeviceUsecase(
    deviceRepository: ref.watch(deviceRepositoryProvider),
    attestationRepository: ref.watch(attestationRepositoryProvider),
    keyRepository: ref.watch(deviceKeyRepositoryProvider),
    keyStoreRepository: ref.watch(deviceKeyStoreRepositoryProvider),
  ),
);

final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => newGroupRepository(ref.watch(gorapeApiProvider)),
);
final groupUsecaseProvider = Provider<GroupUsecase>(
  (ref) => newGroupUsecase(ref.watch(groupRepositoryProvider)),
);

final roleRepositoryProvider = Provider<RoleRepository>(
  (ref) => newRoleRepository(ref.watch(gorapeApiProvider)),
);
final roleUsecaseProvider = Provider<RoleUsecase>(
  (ref) => newRoleUsecase(ref.watch(roleRepositoryProvider)),
);

final policyRepositoryProvider = Provider<DevicePolicyRepository>(
  (ref) => newDevicePolicyRepository(ref.watch(secureStoreProvider)),
);
final policyUsecaseProvider = Provider<DevicePolicyUsecase>(
  (ref) => newDevicePolicyUsecase(ref.watch(policyRepositoryProvider)),
);

final connectionRepositoryProvider = Provider<ConnectionRepository>(
  (ref) => newConnectionRepository(ref.watch(gorapeApiProvider)),
);
final connectionHealthUsecaseProvider = Provider<ConnectionHealthUsecase>(
  (ref) => newConnectionHealthUsecase(ref.watch(connectionRepositoryProvider)),
);
final connectionHealthControllerProvider = Provider<ConnectionHealthController>(
  (ref) =>
      newConnectionHealthController(ref.watch(connectionHealthUsecaseProvider)),
);
