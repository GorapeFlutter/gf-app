import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entity/model/policy.dart';
import 'dependencies.dart';

abstract interface class PolicyController {
  /// GF-00217 — Handles save in PolicyController.
  Future<void> save(LocalDevicePolicy value);
}

/// GF-00012 — Persists local-only policy preferences without calling the API.
final class PolicyControllerImpl extends AsyncNotifier<LocalDevicePolicy>
    implements PolicyController {
  /// GF-00218 — Builds the widget or value for PolicyControllerImpl.
  @override
  Future<LocalDevicePolicy> build() => ref.watch(policyUsecaseProvider).load();

  /// GF-00219 — Handles save in PolicyControllerImpl.
  @override
  Future<void> save(LocalDevicePolicy value) async {
    await ref.read(policyUsecaseProvider).save(value);
    state = AsyncData(value);
  }
}

final policyControllerProvider =
    AsyncNotifierProvider<PolicyControllerImpl, LocalDevicePolicy>(
      PolicyControllerImpl.new,
    );

final policyCapabilitiesProvider = Provider<PolicyCapabilities>(
  /* GF-00220 — Runs an inline callback in top level. */ (ref) =>
      ref.watch(policyUsecaseProvider).capabilities,
);
