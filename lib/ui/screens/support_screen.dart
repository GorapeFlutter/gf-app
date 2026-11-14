import 'package:flutter/material.dart' hide Text;
import '../../l10n/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/providers.dart';
import '../../entity/model/platform.dart';
import '../../entity/model/platform_support.dart';
import '../../entity/response/attestation.dart';
import '../widgets/common.dart';

/// OS support matrix plus the backend's live verifier capabilities.
///
/// The app-side support values are static capabilities of this client. The
/// backend column is fetched from
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
                  'OS別の対応状況',
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
            'この端末: ${current.displayName}。'
            '「アプリ側」はFlutterクライアントの実装状況、'
            '「Gorape」はバックエンドのVerifier対応状況です。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          capabilities.when(
            loading: /* GF-00969 — Runs an inline callback in SupportScreen.build. */
                () => const LoadingView(label: 'Verifier対応状況を取得中...'),
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
            title: 'Android Key Attestation',
            icon: Icons.android,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'Android実機ではAndroid KeystoreにEC P-256鍵を生成し、'
                  'サーバーのチャレンジをKeyGenParameterSpecへバインドして'
                  'Key Attestation証明書チェーン（leaf-first）を取得します。'
                  'GorapeはGoogle Hardware Attestation Root CAまでの'
                  'チェーンを検証します。',
                ),
                const SizedBox(height: 8),
                AppText(
                  'バックエンドの android_trust_anchors が空の場合、'
                  'capabilitiesは "unconfigured" を返し、登録は422で失敗します。',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'iOS / macOS',
            icon: Icons.laptop_mac,
            child: const AppText(
              'Keycloakログインはflutter_appauthで対応します。'
              'ただしGorapeのAttestation VerifierはiOS/macOSを '
              '"unsupported" として返すため、デバイス登録・所有証明は'
              '行いません。App AttestやSecure Enclaveを利用するには'
              'バックエンド側のVerifier追加が必要です。',
            ),
          ),
          SectionCard(
            title: 'Windows / Linux / Web',
            icon: Icons.desktop_windows_outlined,
            child: const AppText(
              'Windows TPM、Linux、Webは現行のGorapeバックエンドで'
              'Attestation対象外です。Windows/Linux/Webでは'
              'flutter_appauthによるOIDCログインも未対応のため、'
              'ログイン画面で明示的に案内します。'
              'iOS/macOS/AndroidのみKeycloakログインを提供します。',
            ),
          ),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'パスキーとデバイス鍵の役割',
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
      title: '対応マトリクス',
      icon: Icons.grid_on_outlined,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 18,
          columns: const [
            DataColumn(label: AppText('プラットフォーム')),
            DataColumn(label: AppText('ログイン')),
            DataColumn(label: AppText('OS鍵')),
            DataColumn(label: AppText('Attestation')),
            DataColumn(label: AppText('Gorape')),
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
                StatusChip(label: 'この端末', color: scheme.primary),
              ],
            ],
          ),
        ),
        DataCell(_mark(context, support.oidcLogin)),
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
