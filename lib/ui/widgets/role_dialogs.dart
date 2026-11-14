import 'package:flutter/material.dart' hide Text;
import '../../l10n/app_text.dart';

import '../../entity/model/device.dart';
import '../../entity/model/group.dart';
import '../../entity/model/role.dart';
import 'common.dart';

class GroupFormResult {
  /// GF-01008 — Initializes GroupFormResult.
  const GroupFormResult({
    required this.slug,
    required this.name,
    required this.status,
  });

  final String slug;
  final String name;
  final String status;
}

/// GF-01009 — Handles show group form dialog in top level.
Future<GroupFormResult?> showGroupFormDialog(
  BuildContext context, {
  Group? initial,
}) {
  return showDialog<GroupFormResult>(
    context: context,
    builder: /* GF-01010 — Runs an inline callback in top level.showGroupFormDialog. */
        (context) => _GroupFormDialog(initial: initial),
  );
}

class _GroupFormDialog extends StatefulWidget {
  /// GF-01011 — Initializes _GroupFormDialog.
  const _GroupFormDialog({this.initial});

  final Group? initial;

  /// GF-01012 — Creates the state object for _GroupFormDialog.
  @override
  State<_GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<_GroupFormDialog> {
  late final TextEditingController _slug;
  late final TextEditingController _name;
  late String _status;
  String? _error;

  /// GF-01013 — Computes _GroupFormDialogState._editing.
  bool get _editing => widget.initial != null;

  /// GF-01014 — Initializes state for _GroupFormDialogState.
  @override
  void initState() {
    super.initState();
    _slug = TextEditingController(text: widget.initial?.slug ?? '');
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _status = widget.initial?.status ?? 'active';
  }

  /// GF-01015 — Releases resources owned by _GroupFormDialogState.
  @override
  void dispose() {
    _slug.dispose();
    _name.dispose();
    super.dispose();
  }

  /// GF-01016 — Builds the widget or value for _GroupFormDialogState.
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: AppText(_editing ? 'グループを編集' : 'グループを作成'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _slug,
              enabled: !_editing,
              decoration: InputDecoration(
                labelText: tr(context, 'Slug'),
                helperText: tr(context, '小文字英数字とハイフン（例: engineering）'),
                border: OutlineInputBorder(),
              ),
              autocorrect: false,
              enableSuggestions: false,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: tr(context, '表示名'),
                border: OutlineInputBorder(),
              ),
            ),
            if (_editing) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: tr(context, 'ステータス'),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: AppText('active')),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: AppText('inactive'),
                  ),
                ],
                onChanged: /* GF-01017 — Runs an inline callback in _GroupFormDialogState.build. */
                    (value) => setState(
                      /* GF-01018 — Runs an inline callback in _GroupFormDialogState.build.callback. */ () =>
                          _status = value ?? 'active',
                    ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              AppText(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: /* GF-01019 — Runs an inline callback in _GroupFormDialogState.build. */
              () => Navigator.of(context).pop(),
          child: const AppText('キャンセル'),
        ),
        FilledButton(
          onPressed: _submit,
          child: AppText(_editing ? '保存' : '作成'),
        ),
      ],
    );
  }

  /// GF-01020 — Handles submit in _GroupFormDialogState.
  void _submit() {
    final slug = _slug.text.trim();
    final name = _name.text.trim();
    if (!_editing && !RegExp(r'^[a-z0-9][a-z0-9-]{0,62}$').hasMatch(slug)) {
      setState(
        /* GF-01021 — Runs an inline callback in _GroupFormDialogState._submit. */ () =>
            _error = 'Slugは小文字英数字とハイフンで入力してください。',
      );
      return;
    }
    if (name.isEmpty) {
      setState(
        /* GF-01022 — Runs an inline callback in _GroupFormDialogState._submit. */ () =>
            _error = '表示名を入力してください。',
      );
      return;
    }
    Navigator.of(
      context,
    ).pop(GroupFormResult(slug: slug, name: name, status: _status));
  }
}

class RoleBindingInput {
  /// GF-01023 — Initializes RoleBindingInput.
  const RoleBindingInput({required this.subject, required this.role});

  final String subject;
  final AccessRole role;
}

/// GF-01024 — Handles show role binding dialog in top level.
Future<RoleBindingInput?> showRoleBindingDialog(
  BuildContext context, {
  String title = 'ロールを付与',
}) {
  return showDialog<RoleBindingInput>(
    context: context,
    builder: /* GF-01025 — Runs an inline callback in top level.showRoleBindingDialog. */
        (context) => _RoleBindingDialog(title: title),
  );
}

class _RoleBindingDialog extends StatefulWidget {
  /// GF-01026 — Initializes _RoleBindingDialog.
  const _RoleBindingDialog({required this.title});

  final String title;

  /// GF-01027 — Creates the state object for _RoleBindingDialog.
  @override
  State<_RoleBindingDialog> createState() => _RoleBindingDialogState();
}

class _RoleBindingDialogState extends State<_RoleBindingDialog> {
  final _subject = TextEditingController();
  AccessRole _role = AccessRole.viewer;
  String? _error;

  /// GF-01028 — Releases resources owned by _RoleBindingDialogState.
  @override
  void dispose() {
    _subject.dispose();
    super.dispose();
  }

  /// GF-01029 — Builds the widget or value for _RoleBindingDialogState.
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: AppText(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _subject,
              decoration: InputDecoration(
                labelText: tr(context, 'OIDC Subject'),
                helperText: tr(context, 'Keycloakのsub（ユーザーのUUID）'),
                border: OutlineInputBorder(),
              ),
              autocorrect: false,
              enableSuggestions: false,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AccessRole>(
              initialValue: _role,
              decoration: InputDecoration(
                labelText: tr(context, 'ロール'),
                border: OutlineInputBorder(),
              ),
              items: [
                for (final role in const [
                  AccessRole.viewer,
                  AccessRole.editor,
                  AccessRole.admin,
                ])
                  DropdownMenuItem(value: role, child: AppText(role.label)),
              ],
              onChanged: /* GF-01030 — Runs an inline callback in _RoleBindingDialogState.build. */
                  (value) => setState(
                    /* GF-01031 — Runs an inline callback in _RoleBindingDialogState.build.callback. */ () =>
                        _role = value ?? AccessRole.viewer,
                  ),
            ),
            const SizedBox(height: 8),
            AppText(
              '自分のロールは変更できません。最後のプロジェクト管理者も削除できません。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              AppText(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: /* GF-01032 — Runs an inline callback in _RoleBindingDialogState.build. */
              () => Navigator.of(context).pop(),
          child: const AppText('キャンセル'),
        ),
        FilledButton(
          onPressed: /* GF-01033 — Runs an inline callback in _RoleBindingDialogState.build. */
              () {
                final subject = _subject.text.trim();
                if (subject.isEmpty) {
                  setState(
                    /* GF-01034 — Runs an inline callback in _RoleBindingDialogState.build.callback. */ () =>
                        _error = 'OIDC Subjectを入力してください。',
                  );
                  return;
                }
                Navigator.of(
                  context,
                ).pop(RoleBindingInput(subject: subject, role: _role));
              },
          child: const AppText('付与'),
        ),
      ],
    );
  }
}

/// GF-01035 — Handles show group device picker in top level.
Future<String?> showGroupDevicePicker(
  BuildContext context, {
  required List<Device> devices,
}) {
  return showDialog<String>(
    context: context,
    builder: /* GF-01036 — Runs an inline callback in top level.showGroupDevicePicker. */
        (context) => AlertDialog(
          title: const AppText('グループにデバイスを追加'),
          content: SizedBox(
            width: 420,
            child: devices.isEmpty
                ? const AppText('追加できるデバイスがありません。')
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final device in devices)
                          ListTile(
                            leading: const Icon(Icons.devices_other),
                            title: AppText(device.displayName),
                            subtitle: AppText(
                              '${platformLabel(device.platform)} • '
                              '${formatTimestamp(device.registeredAt)}',
                            ),
                            onTap: /* GF-01037 — Runs an inline callback in top level.showGroupDevicePicker.callback. */
                                () => Navigator.of(context).pop(device.id),
                          ),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: /* GF-01038 — Runs an inline callback in top level.showGroupDevicePicker.callback. */
                  () => Navigator.of(context).pop(),
              child: const AppText('閉じる'),
            ),
          ],
        ),
  );
}
