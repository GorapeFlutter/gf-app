import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/platform.dart';
import '../repository/secure_store.dart';
import '../entity/model/platform.dart';
import '../entity/model/platform_support.dart';

final platformRepositoryProvider = Provider<PlatformRepository>(
  /* GF-00146 — Runs an inline callback in top level. */ (ref) =>
      newPlatformRepository(),
);

final runtimePlatformProvider = Provider<RuntimePlatform>(
  /* GF-00147 — Runs an inline callback in top level. */ (ref) =>
      ref.watch(platformRepositoryProvider).current(),
);

final platformSupportProvider = Provider<PlatformSupport>(
  /* GF-00148 — Runs an inline callback in top level. */ (ref) => ref
      .watch(platformRepositoryProvider)
      .supportFor(ref.watch(runtimePlatformProvider)),
);

final platformSupportForProvider =
    Provider.family<PlatformSupport, RuntimePlatform>(
      /* GF-00149 — Runs an inline callback in top level. */ (ref, platform) =>
          ref.watch(platformRepositoryProvider).supportFor(platform),
    );

final secureStoreProvider = Provider<SecureStore>(
  /* GF-00150 — Runs an inline callback in top level. */ (ref) =>
      newSecureStore(),
);
