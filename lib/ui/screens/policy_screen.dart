import 'package:flutter/material.dart' hide Text;
import '../../config/langages/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../back/controller/providers.dart';
import '../../entity/model/policy.dart';
import '../widgets/common.dart';

/// Local device policy preferences.
///
/// The current Gorape OpenAPI 3.1 contract has no policy endpoint, so these
/// values are stored on-device only and clearly labelled as not enforced.
class PolicyScreen extends ConsumerWidget {
  /// GF-00844 — Initializes PolicyScreen.
  const PolicyScreen({super.key});

  /// GF-00845 — Builds the widget or value for PolicyScreen.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(policyControllerProvider);
    final capabilities = ref.watch(policyCapabilitiesProvider);
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppText('MCODE-00152', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        AppText(
          'MCODE-00394'
          'MCODE-00310',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Card(
          color: scheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        scheme.onTertiaryContainer,
                        BlendMode.srcIn,
                      ),
                      child: Icon(Icons.info, size: 22),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText(
                        'MCODE-00154',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppText(
                  capabilities.reason,
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        policy.when(
          loading: /* GF-00846 — Runs an inline callback in PolicyScreen.build. */
              () => const LoadingView(label: 'MCODE-00045'),
          error: /* GF-00847 — Runs an inline callback in PolicyScreen.build. */
              (error, _) => ErrorCard(error: error),
          data: /* GF-00848 — Runs an inline callback in PolicyScreen.build. */
              (value) => _PolicyForm(policy: value),
        ),
      ],
    );
  }
}

class _PolicyForm extends ConsumerWidget {
  /// GF-00849 — Initializes _PolicyForm.
  const _PolicyForm({required this.policy});

  final LocalDevicePolicy policy;

  /// GF-00850 — Builds the widget or value for _PolicyForm.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(policyControllerProvider.notifier);

    /// GF-00851 — Handles update in _PolicyForm.build.
    Future<void> update(LocalDevicePolicy next) async {
      try {
        await controller.save(next);
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: AppText('MCODE-00155')));
      } on Object catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText('MCODE-00435', parameters: {'message': error}),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'MCODE-00472',
          icon: Icons.key_outlined,
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const AppText('MCODE-00157'),
                subtitle: const AppText('MCODE-00454'),
                value: policy.requireProofAfterLogin,
                onChanged: /* GF-00852 — Runs an inline callback in _PolicyForm.build. */
                    (value) =>
                        update(policy.copyWith(requireProofAfterLogin: value)),
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const AppText('MCODE-00445'),
                subtitle: const AppText('MCODE-00455'),
                value: policy.allowDevicesWithoutAttestation,
                onChanged: /* GF-00853 — Runs an inline callback in _PolicyForm.build. */
                    (value) => update(
                      policy.copyWith(allowDevicesWithoutAttestation: value),
                    ),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'MCODE-00473',
          icon: Icons.password_outlined,
          child: const AppText('MCODE-00456'),
        ),
        SectionCard(
          title: 'MCODE-00165',
          icon: Icons.lock_outline,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [AppText('MCODE-00479')],
          ),
        ),
      ],
    );
  }
}
