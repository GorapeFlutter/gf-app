import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/platform.dart';
import '../repository/secure_store.dart';
import '../entity/model/platform.dart';
import '../entity/model/platform_support.dart';

final platformRepositoryProvider = Provider<PlatformRepository>(
  (ref) => newPlatformRepository(),
);

final runtimePlatformProvider = Provider<RuntimePlatform>(
  (ref) => ref.watch(platformRepositoryProvider).current(),
);

final platformSupportProvider = Provider<PlatformSupport>(
  (ref) => ref
      .watch(platformRepositoryProvider)
      .supportFor(ref.watch(runtimePlatformProvider)),
);

final platformSupportForProvider =
    Provider.family<PlatformSupport, RuntimePlatform>(
      (ref, platform) =>
          ref.watch(platformRepositoryProvider).supportFor(platform),
    );

final secureStoreProvider = Provider<SecureStore>((ref) => newSecureStore());
