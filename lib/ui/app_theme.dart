import 'package:flutter/material.dart';

import '../share/gorape_colors.dart';

abstract final class AppTheme {
  static const _seed = GorapeColors.pink;

  /// GF-00668 — Handles light in AppTheme.
  static ThemeData light() => _build(Brightness.light);

  /// GF-00669 — Handles dark in AppTheme.
  static ThemeData dark() => _build(Brightness.dark);

  /// GF-00670 — Handles build in AppTheme.
  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
      ),
    );
  }
}
