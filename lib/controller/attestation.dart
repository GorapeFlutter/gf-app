import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entity/model/attestation.dart';
import '../entity/model/device_ref.dart';
import '../entity/response/attestation.dart';
import 'auth.dart';
import 'dependencies.dart';

abstract interface class CapabilitiesController {
  Future<void> reload();
}

final class CapabilitiesControllerImpl
    extends AsyncNotifier<AttestationCapabilities>
    implements CapabilitiesController {
  CapabilitiesControllerImpl(this.projectId);
  final String projectId;

  @override
  Future<AttestationCapabilities> build() async {
    if (!ref.watch(isAuthenticatedProvider)) {
      return const AttestationCapabilities({});
    }
    return ref.watch(attestationUsecaseProvider).capabilities(projectId);
  }

  @override
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(attestationUsecaseProvider).capabilities(projectId),
    );
  }
}

final capabilitiesProvider =
    AsyncNotifierProvider.family<
      CapabilitiesControllerImpl,
      AttestationCapabilities,
      String
    >(CapabilitiesControllerImpl.new);

abstract interface class AttestationsController {
  Future<void> reload();
}

final class AttestationsControllerImpl
    extends AsyncNotifier<List<AttestationRecord>>
    implements AttestationsController {
  AttestationsControllerImpl(this.key);
  final DeviceRef key;

  @override
  Future<List<AttestationRecord>> build() async {
    if (!ref.watch(isAuthenticatedProvider)) return const [];
    return ref
        .watch(attestationUsecaseProvider)
        .list(key.projectId, key.deviceId);
  }

  @override
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(attestationUsecaseProvider)
          .list(key.projectId, key.deviceId),
    );
  }
}

final attestationsProvider =
    AsyncNotifierProvider.family<
      AttestationsControllerImpl,
      List<AttestationRecord>,
      DeviceRef
    >(AttestationsControllerImpl.new);
