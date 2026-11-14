import 'package:flutter/material.dart' hide Text;
import '../../l10n/app_text.dart';

import '../../share/error.dart';
import '../../share/friendly_error.dart';

class ErrorCard extends StatelessWidget {
  /// GF-00978 — Initializes ErrorCard.
  const ErrorCard({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  /// GF-00979 — Builds the widget or value for ErrorCard.
  @override
  Widget build(BuildContext context) {
    final friendly = FriendlyError.from(error);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    scheme.onErrorContainer,
                    BlendMode.srcIn,
                  ),
                  child: Icon(Icons.info, size: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppText(
                    friendly.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppText(
              friendly.message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            if (friendly.guidance != null) ...[
              const SizedBox(height: 8),
              AppText(
                friendly.guidance!,
                style: TextStyle(
                  color: scheme.onErrorContainer.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
            if (onRetry != null && friendly.canRetry) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh, size: 20),
                  label: const AppText('再試行'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  /// GF-00980 — Initializes EmptyState.
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  /// GF-00981 — Builds the widget or value for EmptyState.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 56,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              AppText(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              AppText(
                message,
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

class StatusChip extends StatelessWidget {
  /// GF-00982 — Initializes StatusChip.
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  /// GF-00983 — Initializes StatusChip.status.
  factory StatusChip.status(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'active' || 'verified' || 'implemented' || 'supported' => Colors.green,
      'unconfigured' || 'warning' => Colors.orange,
      'revoked' || 'unsupported' => scheme.error,
      _ => scheme.outline,
    };
    return StatusChip(label: status, color: color);
  }

  /// GF-00984 — Builds the widget or value for StatusChip.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          AppText(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class KeyValueRow extends StatelessWidget {
  /// GF-00985 — Initializes KeyValueRow.
  const KeyValueRow(
    this.label,
    this.value, {
    super.key,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  /// GF-00986 — Builds the widget or value for KeyValueRow.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: AppText(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontFamily: monospace ? 'monospace' : null,
                fontFamilyFallback: monospace
                    ? const ['Menlo', 'Courier']
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  /// GF-00987 — Initializes SectionCard.
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;

  /// GF-00988 — Builds the widget or value for SectionCard.
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: AppText(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (trailing != null) ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  /// GF-00989 — Initializes LoadingView.
  const LoadingView({super.key, this.label = '読み込み中...'});

  final String label;

  /// GF-00990 — Builds the widget or value for LoadingView.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            AppText(label),
          ],
        ),
      ),
    );
  }
}

/// GF-00991 — Handles format timestamp in top level.
String formatTimestamp(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();

  /// GF-00992 — Handles two in top level.formatTimestamp.
  String two(int v) => v.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

/// GF-00993 — Handles platform label in top level.
String platformLabel(String platform) {
  return switch (platform) {
    'android' => 'Android',
    'ios' => 'iOS',
    'macos' => 'macOS',
    'windows' => 'Windows',
    'linux' => 'Linux',
    _ => platform,
  };
}

/// GF-00994 — Handles friendly error in top level.
FriendlyError friendlyError(Object error) => FriendlyError.from(error);

/// GF-00995 — Handles as app exception in top level.
AppException asAppException(Object error) {
  if (error is AppException) return error;
  return UnknownAppException(error.toString());
}
