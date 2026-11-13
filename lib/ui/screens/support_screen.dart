import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/attestation.dart';
import '../../core/config/runtime_platform.dart';
import '../../platform/platform_support.dart';
import '../../state/auth_controller.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';

/// OS support matrix plus the backend's live verifier capabilities.
///
/// The app-side support values are static capabilities of this client. The
/// backend column is fetched from
/// `GET /v1/projects/{projectId}/attestation/capabilities` and can report
/// `unconfigured` even for Android (for example when trust anchors are empty).
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(runtimePlatformProvider);
    final capabilities = ref.watch(capabilitiesProvider(projectId));

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(capabilitiesProvider(projectId).notifier).reload(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'OS別の対応状況',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'バックエンド対応状況を更新',
                onPressed: () =>
                    ref.read(capabilitiesProvider(projectId).notifier).reload(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          Text(
            'この端末: ${current.displayName}。'
            '「アプリ側」はFlutterクライアントの実装状況、'
            '「Gorape」はバックエンドのVerifier対応状況です。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          capabilities.when(
            loading: () => const LoadingView(label: 'Verifier対応状況を取得中...'),
            error: (error, _) => ErrorCard(
              error: error,
              onRetry: () =>
                  ref.read(capabilitiesProvider(projectId).notifier).reload(),
            ),
            data: (value) => _SupportTable(current: current, backend: value),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Android Key Attestation',
            icon: Icons.android,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Android実機ではAndroid KeystoreにEC P-256鍵を生成し、'
                  'サーバーのチャレンジをKeyGenParameterSpecへバインドして'
                  'Key Attestation証明書チェーン（leaf-first）を取得します。'
                  'GorapeはGoogle Hardware Attestation Root CAまでの'
                  'チェーンを検証します。',
                ),
                const SizedBox(height: 8),
                Text(
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
            child: const Text(
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
            child: const Text(
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
                  Text(
                    'パスキーとデバイス鍵の役割',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(PlatformSupport.passkeyDelegationNote),
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
  const _SupportTable({required this.current, required this.backend});

  final RuntimePlatform current;
  final AttestationCapabilities backend;

  @override
  Widget build(BuildContext context) {
    final platforms = [
      RuntimePlatform.android,
      RuntimePlatform.ios,
      RuntimePlatform.macos,
      RuntimePlatform.windows,
      RuntimePlatform.linux,
      RuntimePlatform.web,
    ];
    return SectionCard(
      title: '対応マトリクス',
      icon: Icons.grid_on_outlined,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 18,
          columns: const [
            DataColumn(label: Text('プラットフォーム')),
            DataColumn(label: Text('ログイン')),
            DataColumn(label: Text('OS鍵')),
            DataColumn(label: Text('Attestation')),
            DataColumn(label: Text('Gorape')),
          ],
          rows: [
            for (final platform in platforms)
              _row(context, PlatformSupport.forRuntime(platform)),
          ],
        ),
      ),
    );
  }

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
              Text(platformName(support.platform)),
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

  Widget _mark(BuildContext context, bool supported) {
    return Icon(
      supported ? Icons.check_circle : Icons.remove_circle_outline,
      size: 18,
      color: supported ? Colors.green : Theme.of(context).colorScheme.error,
    );
  }

  static String platformName(String platform) => platformLabel(platform);
}
