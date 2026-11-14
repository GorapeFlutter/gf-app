import 'package:flutter/material.dart' hide Text;
import '../../l10n/app_text.dart';

import '../../entity/model/role.dart';

/// Compact role indicator used across cluster/project/group screens.
class RoleBadge extends StatelessWidget {
  /// GF-00996 — Initializes RoleBadge.
  const RoleBadge({super.key, required this.role, this.showIcon = true});

  final AccessRole role;
  final bool showIcon;

  /// GF-00997 — Handles color of in RoleBadge.
  static Color colorOf(AccessRole role, ColorScheme scheme) {
    return switch (role) {
      AccessRole.admin => Colors.deepPurple,
      AccessRole.editor => Colors.orange,
      AccessRole.viewer => Colors.blue,
      AccessRole.none => scheme.outline,
    };
  }

  /// GF-00998 — Handles icon of in RoleBadge.
  static IconData iconOf(AccessRole role) {
    return switch (role) {
      AccessRole.admin => Icons.admin_panel_settings,
      AccessRole.editor => Icons.edit_note,
      AccessRole.viewer => Icons.visibility_outlined,
      AccessRole.none => Icons.lock_outline,
    };
  }

  /// GF-00999 — Builds the widget or value for RoleBadge.
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = colorOf(role, scheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(iconOf(role), size: 14, color: color),
            const SizedBox(width: 4),
          ],
          AppText(
            role.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Explains the current role and lists the capabilities it enables.
class RoleCapabilityCard extends StatelessWidget {
  /// GF-01000 — Initializes RoleCapabilityCard.
  const RoleCapabilityCard({
    super.key,
    required this.role,
    required this.scopeLabel,
    this.footnote,
  });

  final AccessRole role;
  final String scopeLabel;
  final String? footnote;

  /// GF-01001 — Builds the widget or value for RoleCapabilityCard.
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = RoleBadge.colorOf(role, scheme);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(RoleBadge.iconOf(role), color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: AppText(
                    '$scopeLabelのロール',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                RoleBadge(role: role),
              ],
            ),
            const SizedBox(height: 10),
            AppText(role.description),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Capability(label: '参照', enabled: role.canView, color: color),
                _Capability(label: '編集操作', enabled: role.canEdit, color: color),
                _Capability(
                  label: '管理操作',
                  enabled: role.canAdmin,
                  color: color,
                ),
              ],
            ),
            if (footnote != null) ...[
              const SizedBox(height: 10),
              AppText(
                footnote!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact inline notice used to explain the current role's restrictions.
class RoleNotice extends StatelessWidget {
  /// GF-01002 — Initializes RoleNotice.
  const RoleNotice({
    super.key,
    required this.role,
    required this.message,
    this.scopeLabel,
  });

  final AccessRole role;
  final String message;
  final String? scopeLabel;

  /// GF-01003 — Builds the widget or value for RoleNotice.
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = RoleBadge.colorOf(role, scheme);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(RoleBadge.iconOf(role), color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (scopeLabel != null) ...[
                        Flexible(
                          child: AppText(
                            scopeLabel!,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      RoleBadge(role: role, showIcon: false),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    message,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the Keycloak token grants no role for the current scope.
///
/// Screens still exist for this state so the user can see why nothing is
/// available instead of getting a blank page.
class RoleNoneScreen extends StatelessWidget {
  /// GF-01004 — Initializes RoleNoneScreen.
  const RoleNoneScreen({
    super.key,
    required this.scopeLabel,
    this.message,
    this.action,
  });

  final String scopeLabel;
  final String? message;
  final Widget? action;

  /// GF-01005 — Builds the widget or value for RoleNoneScreen.
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 56, color: scheme.outline),
              const SizedBox(height: 12),
              AppText(
                '$scopeLabelのロールがありません',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              AppText(
                message ??
                    'Keycloakトークンにこのスコープのロールが含まれていません。'
                        'realmロール admin / editor / viewer、または'
                        'gorape_project_role / gorape_group_<slug>_role 属性を'
                        'アクセストークンへマッピングしてください。'
                        '設定変更後は再ログインで反映されます。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class _Capability extends StatelessWidget {
  /// GF-01006 — Initializes _Capability.
  const _Capability({
    required this.label,
    required this.enabled,
    required this.color,
  });

  final String label;
  final bool enabled;
  final Color color;

  /// GF-01007 — Builds the widget or value for _Capability.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: enabled
            ? color.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.check_circle_outline : Icons.remove_circle_outline,
            size: 15,
            color: enabled ? color : Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 5),
          AppText(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: enabled ? color : Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
