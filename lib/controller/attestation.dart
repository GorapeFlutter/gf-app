import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entity/model/attestation.dart';
import '../entity/model/device_ref.dart';
import '../entity/response/attestation.dart';
import 'auth.dart';
import 'dependencies.dart';

abstract interface class CapabilitiesController {
  /// GF-00117 — Handles reload in CapabilitiesController.
  Future<void> reload();
}

/// GF-00004 — Loads verifier capabilities and device attestation records.
final class CapabilitiesControllerImpl
    extends AsyncNotifier<AttestationCapabilities>
    implements CapabilitiesController {
  /// GF-00118 — Initializes CapabilitiesControllerImpl.
  CapabilitiesControllerImpl(this.projectId);
  final String projectId;

  /// GF-00119 — Builds the widget or value for CapabilitiesControllerImpl.
  @override
  Future<AttestationCapabilities> build() async {
    if (!ref.watch(isAuthenticatedProvider)) {
      return const AttestationCapabilities({});
    }
    return ref.watch(attestationUsecaseProvider).capabilities(projectId);
  }

  /// GF-00120 — Handles reload in CapabilitiesControllerImpl.
  @override
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      /* GF-00121 — Runs an inline callback in CapabilitiesControllerImpl.reload. */ () =>
          ref.read(attestationUsecaseProvider).capabilities(projectId),
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
  /// GF-00122 — Handles reload in AttestationsController.
  Future<void> reload();
}

final class AttestationsControllerImpl
    extends AsyncNotifier<List<AttestationRecord>>
    implements AttestationsController {
  /// GF-00123 — Initializes AttestationsControllerImpl.
  AttestationsControllerImpl(this.key);
  final DeviceRef key;

  /// GF-00124 — Builds the widget or value for AttestationsControllerImpl.
  @override
  Future<List<AttestationRecord>> build() async {
    if (!ref.watch(isAuthenticatedProvider)) return const [];
    return ref
        .watch(attestationUsecaseProvider)
        .list(key.projectId, key.deviceId);
  }

  /// GF-00125 — Handles reload in AttestationsControllerImpl.
  @override
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      /* GF-00126 — Runs an inline callback in AttestationsControllerImpl.reload. */ () =>
          ref
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
