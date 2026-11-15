import 'package:flutter/material.dart' hide Text;
import '../../config/langages/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../back/controller/providers.dart';
import '../../entity/model/platform_support.dart';
import '../../entity/model/role.dart';
import '../widgets/common.dart';
import '../widgets/role_badge.dart';

class RegisterDeviceScreen extends ConsumerStatefulWidget {
  /// GF-00906 — Initializes RegisterDeviceScreen.
  const RegisterDeviceScreen({
    super.key,
    required this.projectId,
    required this.onRegistered,
    required this.onOpenDevices,
  });

  final String projectId;
  final void Function(String deviceId) onRegistered;
  final VoidCallback onOpenDevices;

  /// GF-00907 — Creates the state object for RegisterDeviceScreen.
  @override
  ConsumerState<RegisterDeviceScreen> createState() =>
      _RegisterDeviceScreenState();
}

class _RegisterDeviceScreenState extends ConsumerState<RegisterDeviceScreen> {
  final _nameController = TextEditingController();
  bool _busy = false;
  Object? _error;

  /// GF-00908 — Initializes state for _RegisterDeviceScreenState.
  @override
  void initState() {
    super.initState();
    _nameController.text = '';
  }

  /// GF-00909 — Releases resources owned by _RegisterDeviceScreenState.
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// GF-00910 — Builds the widget or value for _RegisterDeviceScreenState.
  @override
  Widget build(BuildContext context) {
    final platform = ref.watch(runtimePlatformProvider);
    final support = ref.watch(platformSupportProvider);
    final role = ref.watch(projectRoleProvider(widget.projectId));
    final passkeyReady = support.passkeyCeremony;
    final canRegister =
        !_busy &&
        role.canEdit &&
        passkeyReady &&
        _nameController.text.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppText('MCODE-00441', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        AppText('MCODE-00467', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        if (!role.canEdit)
          RoleNotice(
            role: role,
            scopeLabel: 'MCODE-00052',
            message: role == AccessRole.none
                ? 'Keycloakトークンにこのプロジェクトのロールがありません。'
                      'Gorape側でeditor権限があっても、UIからは登録できません。'
                : '閲覧者のためデバイスを登録できません。管理者または編集者のロールが必要です。',
          ),
        if (_error != null) ...[
          ErrorCard(error: _error!, compact: true),
          const SizedBox(height: 12),
        ],
        SectionCard(
          title: 'MCODE-00099',
          icon: Icons.key,
          trailing: StatusChip(
            label: platform.displayName,
            color: Theme.of(context).colorScheme.primary,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CheckLine(
                label: 'MCODE-00477',
                ok: passkeyReady,
                detail: passkeyReady
                    ? 'OS / browser credential provider'
                    : '未対応',
              ),
              _CheckLine(
                label: 'MCODE-00478',
                ok: passkeyReady,
                detail: passkeyReady ? 'MCODE-00488' : 'MCODE-00497',
              ),
              const SizedBox(height: 8),
              AppText(
                support.note,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              AppText(
                'MCODE-00468',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'MCODE-00503',
          icon: Icons.cloud_outlined,
          child: const AppText('MCODE-00469'),
        ),
        SectionCard(
          title: 'MCODE-00102',
          icon: Icons.edit_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                enabled: !_busy,
                onChanged: /* GF-00919 — Runs an inline callback in _RegisterDeviceScreenState.build. */
                    (_) => setState(
                      /* GF-00920 — Runs an inline callback in _RegisterDeviceScreenState.build.callback. */ () {},
                    ),
                decoration: InputDecoration(
                  labelText: tr(context, '表示名'),
                  hintText: tr(context, '例: Pixel 8 Pro'),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: canRegister ? _register : null,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.add, size: 22),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: AppText(_busy ? 'MCODE-00106' : 'MCODE-00485'),
                ),
              ),
              if (!passkeyReady)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AppText(
                    'MCODE-00470',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (!role.canEdit)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AppText(
                    'MCODE-00108',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.help_outline),
            title: const AppText('MCODE-00109'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const _FlowStep('1', 'MCODE-00489'),
              const _FlowStep('2', 'MCODE-00490'),
              const _FlowStep('3', 'MCODE-00491'),
              const _FlowStep('4', 'MCODE-00492'),
              const _FlowStep('5', 'MCODE-00493'),
              const SizedBox(height: 8),
              AppText(
                PlatformSupport.passkeyDelegationNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// GF-00921 — Handles register in _RegisterDeviceScreenState.
  Future<void> _register() async {
    // GF-02096 — Reset form errors and mark registration as in progress.
    setState(
      /* GF-00922 — Runs an inline callback in _RegisterDeviceScreenState._register. */ () {
        _busy = true;
        _error = null;
      },
    );
    try {
      // GF-02097 — Invoke the WebAuthn device-registration ceremony for this platform.
      final result = await ref
          .read(deviceControllerProvider)
          .registerPasskey(
            projectId: widget.projectId,
            displayName: _nameController.text,
          );
      if (!mounted) return;
      // GF-02098 — Present the verified device details and assurance level.
      await showDialog<void>(
        context: context,
        builder: /* GF-00923 — Runs an inline callback in _RegisterDeviceScreenState._register. */
            (context) => AlertDialog(
              icon: const Icon(Icons.verified_user),
              title: const AppText('MCODE-00110'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KeyValueRow('MCODE-00103', result.device.displayName),
                  KeyValueRow('Assurance Level', result.assuranceLevel),
                  KeyValueRow('Attestation format', result.attestationType),
                  KeyValueRow('Security Level', result.securityLevel),
                  KeyValueRow(
                    'Device-bound (BE=0)',
                    result.backupEligible ? 'No (Syncable)' : 'Yes (Device-bound)',
                  ),
                  KeyValueRow('Verifier', result.verifierVersion),
                  KeyValueRow('Device ID', result.device.id, monospace: true),
                  const SizedBox(height: 8),
                  const AppText('MCODE-00471'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: /* GF-00924 — Runs an inline callback in _RegisterDeviceScreenState._register.callback. */
                      () => Navigator.pop(context),
                  child: const AppText('MCODE-00112'),
                ),
                FilledButton(
                  onPressed: /* GF-00925 — Runs an inline callback in _RegisterDeviceScreenState._register.callback. */
                      () {
                        Navigator.pop(context);
                        widget.onRegistered(result.device.id);
                      },
                  child: const AppText('MCODE-00113'),
                ),
              ],
            ),
      );
      // GF-02099 — Notify the parent and clear the submitted device name.
      if (mounted) widget.onRegistered(result.device.id);
      _nameController.clear();
    } on Object catch (error) {
      // GF-02100 — Keep registration failures visible in the form.
      if (mounted) {
        setState(
          /* GF-00926 — Runs an inline callback in _RegisterDeviceScreenState._register. */ () =>
              _error = error,
        );
      }
    } finally {
      // GF-02101 — Restore the form's idle state after every outcome.
      if (mounted) {
        setState(
          /* GF-00927 — Runs an inline callback in _RegisterDeviceScreenState._register. */ () =>
              _busy = false,
        );
      }
    }
  }
}

class _CheckLine extends StatelessWidget {
  /// GF-00928 — Initializes _CheckLine.
  const _CheckLine({
    required this.label,
    required this.ok,
    required this.detail,
  });

  final String label;
  final bool ok;
  final String detail;

  /// GF-00929 — Builds the widget or value for _CheckLine.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel_outlined,
            size: 18,
            color: ok ? Colors.green : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(label),
                AppText(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  /// GF-00930 — Initializes _FlowStep.
  const _FlowStep(this.number, this.text);

  final String number;
  final String text;

  /// GF-00931 — Builds the widget or value for _FlowStep.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            child: AppText(number, style: const TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(child: AppText(text)),
        ],
      ),
    );
  }
}
