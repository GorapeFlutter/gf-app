import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'base.dart';

const _languageStorageKey = 'gf_app.language';

final languageProvider = AsyncNotifierProvider<LanguageController, Locale>(
  LanguageController.new,
);

/// GF-00013 — Loads and saves the locally selected display language.
final class LanguageController extends AsyncNotifier<Locale> {
  /// GF-00215 — Builds the widget or value for LanguageController.
  @override
  Future<Locale> build() async {
    // GF-02072 — Restore the saved language, defaulting to Japanese.
    final stored = await ref
        .watch(secureStoreProvider)
        .read(_languageStorageKey);
    return Locale(stored == 'en' ? 'en' : 'ja');
  }

  /// GF-00216 — Handles set language in LanguageController.
  Future<void> setLanguage(String languageCode) async {
    // GF-02073 — Accept only the languages supported by the app.
    if (languageCode != 'ja' && languageCode != 'en') {
      throw ArgumentError.value(languageCode, 'languageCode');
    }
    // GF-02074 — Persist the selected language and update reactive UI state.
    await ref
        .read(secureStoreProvider)
        .write(_languageStorageKey, languageCode);
    state = AsyncData(Locale(languageCode));
  }
}
