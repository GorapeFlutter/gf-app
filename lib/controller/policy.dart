import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entity/model/policy.dart';
import 'dependencies.dart';

abstract interface class PolicyController {
  Future<void> save(LocalDevicePolicy value);
}

final class PolicyControllerImpl extends AsyncNotifier<LocalDevicePolicy>
    implements PolicyController {
  @override
  Future<LocalDevicePolicy> build() => ref.watch(policyUsecaseProvider).load();

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
  (ref) => ref.watch(policyUsecaseProvider).capabilities,
);
