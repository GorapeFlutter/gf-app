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

final gorapeApiProvider = Provider<GorapeApi>(
  /* GF-00162 — Runs an inline callback in top level. */ (ref) {
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
      refreshAccessToken: /* GF-00163 — Runs an inline callback in top level.callback. */
          () async {
            final auth = ref.read(authControllerProvider.notifier);
            final refreshed = await auth.refreshSession();
            if (!refreshed) await auth.handleUnauthorized();
            return refreshed;
          },
    );
  },
);

final projectRepositoryProvider = Provider<ProjectRepository>(
  /* GF-00164 — Runs an inline callback in top level. */ (ref) =>
      newProjectRepository(ref.watch(gorapeApiProvider)),
);
final projectUsecaseProvider = Provider<ProjectUsecase>(
  /* GF-00165 — Runs an inline callback in top level. */ (ref) =>
      newProjectUsecase(ref.watch(projectRepositoryProvider)),
);

final deviceRepositoryProvider = Provider<DeviceRepository>(
  /* GF-00166 — Runs an inline callback in top level. */ (ref) =>
      newDeviceRepository(ref.watch(gorapeApiProvider)),
);
final attestationRepositoryProvider = Provider<AttestationRepository>(
  /* GF-00167 — Runs an inline callback in top level. */ (ref) =>
      newAttestationRepository(ref.watch(gorapeApiProvider)),
);
final attestationUsecaseProvider = Provider<AttestationUsecase>(
  /* GF-00168 — Runs an inline callback in top level. */ (ref) =>
      newAttestationUsecase(ref.watch(attestationRepositoryProvider)),
);

final deviceKeyRepositoryProvider = Provider<DeviceKeyRepository>(
  /* GF-00169 — Runs an inline callback in top level. */ (ref) =>
      newDeviceKeyRepository(ref.watch(runtimePlatformProvider)),
);
final deviceKeyStoreRepositoryProvider = Provider<DeviceKeyStoreRepository>(
  /* GF-00170 — Runs an inline callback in top level. */ (ref) =>
      newDeviceKeyStoreRepository(ref.watch(secureStoreProvider)),
);
final deviceUsecaseProvider = Provider<DeviceUsecase>(
  /* GF-00171 — Runs an inline callback in top level. */ (ref) =>
      newDeviceUsecase(
        deviceRepository: ref.watch(deviceRepositoryProvider),
        attestationRepository: ref.watch(attestationRepositoryProvider),
        keyRepository: ref.watch(deviceKeyRepositoryProvider),
        keyStoreRepository: ref.watch(deviceKeyStoreRepositoryProvider),
      ),
);

final groupRepositoryProvider = Provider<GroupRepository>(
  /* GF-00172 — Runs an inline callback in top level. */ (ref) =>
      newGroupRepository(ref.watch(gorapeApiProvider)),
);
final groupUsecaseProvider = Provider<GroupUsecase>(
  /* GF-00173 — Runs an inline callback in top level. */ (ref) =>
      newGroupUsecase(ref.watch(groupRepositoryProvider)),
);

final roleRepositoryProvider = Provider<RoleRepository>(
  /* GF-00174 — Runs an inline callback in top level. */ (ref) =>
      newRoleRepository(ref.watch(gorapeApiProvider)),
);
final roleUsecaseProvider = Provider<RoleUsecase>(
  /* GF-00175 — Runs an inline callback in top level. */ (ref) =>
      newRoleUsecase(ref.watch(roleRepositoryProvider)),
);

final policyRepositoryProvider = Provider<DevicePolicyRepository>(
  /* GF-00176 — Runs an inline callback in top level. */ (ref) =>
      newDevicePolicyRepository(ref.watch(secureStoreProvider)),
);
final policyUsecaseProvider = Provider<DevicePolicyUsecase>(
  /* GF-00177 — Runs an inline callback in top level. */ (ref) =>
      newDevicePolicyUsecase(ref.watch(policyRepositoryProvider)),
);

final connectionRepositoryProvider = Provider<ConnectionRepository>(
  /* GF-00178 — Runs an inline callback in top level. */ (ref) =>
      newConnectionRepository(ref.watch(gorapeApiProvider)),
);
final connectionHealthUsecaseProvider = Provider<ConnectionHealthUsecase>(
  /* GF-00179 — Runs an inline callback in top level. */ (ref) =>
      newConnectionHealthUsecase(ref.watch(connectionRepositoryProvider)),
);
final connectionHealthControllerProvider = Provider<ConnectionHealthController>(
  /* GF-00180 — Runs an inline callback in top level. */ (ref) =>
      newConnectionHealthController(ref.watch(connectionHealthUsecaseProvider)),
);
