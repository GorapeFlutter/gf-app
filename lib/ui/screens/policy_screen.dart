import 'package:flutter/material.dart' hide Text;
import '../../l10n/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/providers.dart';
import '../../entity/model/policy.dart';
import '../widgets/common.dart';

/// Local device policy preferences.
///
/// The current Gorape OpenAPI 3.1 contract has no policy endpoint, so these
/// values are stored on-device only and clearly labelled as not enforced.
class PolicyScreen extends ConsumerWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(policyControllerProvider);
    final capabilities = ref.watch(policyCapabilitiesProvider);
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppText(
          'デバイスポリシー（ローカルのみ）',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        AppText(
          'この画面の値は端末内に保存される希望値です。'
          'Gorapeバックエンドでは強制されません。',
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
                        'バックエンドAPI未提供',
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
          loading: () => const LoadingView(label: 'ポリシーを読み込み中...'),
          error: (error, _) => ErrorCard(error: error),
          data: (value) => _PolicyForm(policy: value),
        ),
      ],
    );
  }
}

class _PolicyForm extends ConsumerWidget {
  const _PolicyForm({required this.policy});

  final LocalDevicePolicy policy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(policyControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    Future<void> update(LocalDevicePolicy next) async {
      try {
        await controller.save(next);
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: AppText('ローカルポリシーを保存しました。')));
      } on Object catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: AppText('保存に失敗しました: $error')));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'ログインとデバイス鍵',
          icon: Icons.key_outlined,
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const AppText('ログイン後の所有証明を推奨'),
                subtitle: const AppText(
                  'Keycloakログイン後にチャレンジ署名を促すUIを表示します。'
                  '（アプリ内の案内のみ）',
                ),
                value: policy.requireProofAfterLogin,
                onChanged: (value) =>
                    update(policy.copyWith(requireProofAfterLogin: value)),
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const AppText('Attestationなしのデバイスを許可'),
                subtitle: const AppText(
                  'バックエンドの登録APIはAttestation証拠を要求します。'
                  'この設定は表示上の希望値であり、登録可否を変えません。',
                ),
                value: policy.allowDevicesWithoutAttestation,
                onChanged: (value) => update(
                  policy.copyWith(allowDevicesWithoutAttestation: value),
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'パスキーとデバイス鍵',
          icon: Icons.password_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RadioGroup<PasskeyStrategy>(
                groupValue: policy.passkeyStrategy,
                onChanged: (value) {
                  if (value == null) return;
                  update(policy.copyWith(passkeyStrategy: value));
                },
                child: const Column(
                  children: [
                    RadioListTile<PasskeyStrategy>(
                      contentPadding: EdgeInsets.zero,
                      value: PasskeyStrategy.dedicatedDeviceKey,
                      title: AppText('デバイス専用鍵（推奨）'),
                      subtitle: AppText(
                        'Gorapeに登録したOS保護鍵で所有証明を行います。'
                        'Keycloakのパスキーとは独立しています。',
                      ),
                    ),
                    RadioListTile<PasskeyStrategy>(
                      contentPadding: EdgeInsets.zero,
                      value: PasskeyStrategy.sharedPasskey,
                      title: AppText('Keycloakの共有パスキー'),
                      subtitle: AppText(
                        'パスキーはKeycloakアカウントに紐づき、複数端末で共有されます。'
                        'Gorapeのデバイス鍵による所有証明とは別物です。',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AppText(
                'パスキー・MFA・アカウント回復はKeycloakの責務です。'
                'このアプリはパスキーの秘密情報を保存せず、'
                'Gorape APIにはアクセストークンのみを送信します。',
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'この設定の扱い',
          icon: Icons.lock_outline,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                '• 値はOSのセキュアストレージに保存されます。\n'
                '• Gorapeへは送信されません（ポリシーAPIがないため）。\n'
                '• サーバー側の強制が必要な場合は、Gorapeに'
                'デバイスポリシーAPIを追加してから接続してください。',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
