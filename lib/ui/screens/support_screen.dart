import 'package:flutter/material.dart' hide Text;
import '../../config/langages/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../back/controller/providers.dart';
import '../../entity/model/platform.dart';
import '../../entity/model/platform_support.dart';
import '../../entity/response/attestation.dart';
import '../widgets/common.dart';

/// Platform passkey support plus legacy verifier status.
///
/// The app-side support values are static capabilities of this client. The
/// legacy verifier column is fetched from
/// `GET /v1/projects/{projectId}/attestation/capabilities` and can report
/// `unconfigured` even for Android (for example when trust anchors are empty).
class SupportScreen extends ConsumerWidget {
  /// GF-00965 — Initializes SupportScreen.
  const SupportScreen({super.key, required this.projectId});

  final String projectId;

  /// GF-00966 — Builds the widget or value for SupportScreen.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(runtimePlatformProvider);
    final capabilities = ref.watch(capabilitiesProvider(projectId));
    final supports = [
      for (final platform in const [
        RuntimePlatform.android,
        RuntimePlatform.ios,
        RuntimePlatform.macos,
        RuntimePlatform.windows,
        RuntimePlatform.linux,
        RuntimePlatform.web,
      ])
        ref.watch(platformSupportForProvider(platform)),
    ];

    return RefreshIndicator(
      onRefresh: /* GF-00967 — Runs an inline callback in SupportScreen.build. */
          () => ref.read(capabilitiesProvider(projectId).notifier).reload(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  'MCODE-00069',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: tr(context, 'バックエンド対応状況を更新'),
                onPressed: /* GF-00968 — Runs an inline callback in SupportScreen.build. */
                    () => ref
                        .read(capabilitiesProvider(projectId).notifier)
                        .reload(),
                icon: Icon(Icons.refresh, size: 22),
              ),
            ],
          ),
          AppText(
            'MCODE-00495',
            parameters: {'name': current.displayName},
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          capabilities.when(
            loading: /* GF-00969 — Runs an inline callback in SupportScreen.build. */
                () => const LoadingView(label: 'MCODE-00044'),
            error: /* GF-00970 — Runs an inline callback in SupportScreen.build. */
                (error, _) => ErrorCard(
                  error: error,
                  onRetry: /* GF-00971 — Runs an inline callback in SupportScreen.build.callback. */
                      () => ref
                          .read(capabilitiesProvider(projectId).notifier)
                          .reload(),
                ),
            data: /* GF-00972 — Runs an inline callback in SupportScreen.build. */
                (value) => _SupportTable(
                  current: current,
                  backend: value,
                  supports: supports,
                ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'MCODE-00474',
            icon: Icons.android,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText('MCODE-00457'),
                const SizedBox(height: 8),
                AppText(
                  'MCODE-00458',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'MCODE-00501',
            icon: Icons.laptop_mac,
            child: const AppText('MCODE-00459'),
          ),
          SectionCard(
            title: 'MCODE-00502',
            icon: Icons.desktop_windows_outlined,
            child: const AppText('MCODE-00460'),
          ),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'MCODE-00461',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  const AppText(PlatformSupport.passkeyDelegationNote),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportTable extends StatelessWidget {
  /// GF-00973 — Initializes _SupportTable.
  const _SupportTable({
    required this.current,
    required this.backend,
    required this.supports,
  });

  final RuntimePlatform current;
  final AttestationCapabilities backend;
  final List<PlatformSupport> supports;

  /// GF-00974 — Builds the widget or value for _SupportTable.
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'MCODE-00171',
      icon: Icons.grid_on_outlined,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 18,
          columns: const [
            DataColumn(label: AppText('MCODE-00130')),
            DataColumn(label: AppText('MCODE-00446')),
            DataColumn(label: AppText('MCODE-00447')),
            DataColumn(label: AppText('MCODE-00448')),
            DataColumn(label: AppText('MCODE-00449')),
            DataColumn(label: AppText('MCODE-00450')),
          ],
          rows: [for (final support in supports) _row(context, support)],
        ),
      ),
    );
  }

  /// GF-00975 — Handles row in _SupportTable.
  DataRow _row(BuildContext context, PlatformSupport support) {
    final scheme = Theme.of(context).colorScheme;
    final backendStatus = backend.statusFor(support.platform);
    return DataRow(
      selected: support.platform == current.wireName,
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(platformName(support.platform)),
              if (support.platform == current.wireName) ...[
                const SizedBox(width: 6),
                StatusChip(label: 'MCODE-00099', color: scheme.primary),
              ],
            ],
          ),
        ),
        DataCell(_mark(context, support.oidcLogin)),
        DataCell(_mark(context, support.passkeyCeremony)),
        DataCell(_mark(context, support.localKeyGeneration)),
        DataCell(_mark(context, support.attestationFlow)),
        DataCell(StatusChip.status(context, backendStatus)),
      ],
    );
  }

  /// GF-00976 — Handles mark in _SupportTable.
  Widget _mark(BuildContext context, bool supported) {
    return Icon(
      supported ? Icons.check_circle : Icons.remove_circle_outline,
      size: 18,
      color: supported ? Colors.green : Theme.of(context).colorScheme.error,
    );
  }

  /// GF-00977 — Handles platform name in _SupportTable.
  static String platformName(String platform) => platformLabel(platform);
}
