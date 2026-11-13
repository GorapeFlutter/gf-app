import 'package:flutter/material.dart' hide Text;
import '../../l10n/app_text.dart';

import '../../entity/model/device.dart';
import '../../entity/model/group.dart';
import '../../entity/model/role.dart';
import 'common.dart';

class GroupFormResult {
  const GroupFormResult({
    required this.slug,
    required this.name,
    required this.status,
  });

  final String slug;
  final String name;
  final String status;
}

Future<GroupFormResult?> showGroupFormDialog(
  BuildContext context, {
  Group? initial,
}) {
  return showDialog<GroupFormResult>(
    context: context,
    builder: (context) => _GroupFormDialog(initial: initial),
  );
}

class _GroupFormDialog extends StatefulWidget {
  const _GroupFormDialog({this.initial});

  final Group? initial;

  @override
  State<_GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<_GroupFormDialog> {
  late final TextEditingController _slug;
  late final TextEditingController _name;
  late String _status;
  String? _error;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _slug = TextEditingController(text: widget.initial?.slug ?? '');
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _status = widget.initial?.status ?? 'active';
  }

  @override
  void dispose() {
    _slug.dispose();
    _name.dispose();
    super.dispose();
  }

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
                onChanged: (value) =>
                    setState(() => _status = value ?? 'active'),
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
          onPressed: () => Navigator.of(context).pop(),
          child: const AppText('キャンセル'),
        ),
        FilledButton(
          onPressed: _submit,
          child: AppText(_editing ? '保存' : '作成'),
        ),
      ],
    );
  }

  void _submit() {
    final slug = _slug.text.trim();
    final name = _name.text.trim();
    if (!_editing && !RegExp(r'^[a-z0-9][a-z0-9-]{0,62}$').hasMatch(slug)) {
      setState(() => _error = 'Slugは小文字英数字とハイフンで入力してください。');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = '表示名を入力してください。');
      return;
    }
    Navigator.of(
      context,
    ).pop(GroupFormResult(slug: slug, name: name, status: _status));
  }
}

class RoleBindingInput {
  const RoleBindingInput({required this.subject, required this.role});

  final String subject;
  final AccessRole role;
}

Future<RoleBindingInput?> showRoleBindingDialog(
  BuildContext context, {
  String title = 'ロールを付与',
}) {
  return showDialog<RoleBindingInput>(
    context: context,
    builder: (context) => _RoleBindingDialog(title: title),
  );
}

class _RoleBindingDialog extends StatefulWidget {
  const _RoleBindingDialog({required this.title});

  final String title;

  @override
  State<_RoleBindingDialog> createState() => _RoleBindingDialogState();
}

class _RoleBindingDialogState extends State<_RoleBindingDialog> {
  final _subject = TextEditingController();
  AccessRole _role = AccessRole.viewer;
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    super.dispose();
  }

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
              onChanged: (value) =>
                  setState(() => _role = value ?? AccessRole.viewer),
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
          onPressed: () => Navigator.of(context).pop(),
          child: const AppText('キャンセル'),
        ),
        FilledButton(
          onPressed: () {
            final subject = _subject.text.trim();
            if (subject.isEmpty) {
              setState(() => _error = 'OIDC Subjectを入力してください。');
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

Future<String?> showGroupDevicePicker(
  BuildContext context, {
  required List<Device> devices,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
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
                        onTap: () => Navigator.of(context).pop(device.id),
                      ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const AppText('閉じる'),
        ),
      ],
    ),
  );
}
