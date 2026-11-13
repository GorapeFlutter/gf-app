import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'base.dart';

const _languageStorageKey = 'gf_app.language';

final languageProvider = AsyncNotifierProvider<LanguageController, Locale>(
  LanguageController.new,
);

final class LanguageController extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final stored = await ref
        .watch(secureStoreProvider)
        .read(_languageStorageKey);
    return Locale(stored == 'en' ? 'en' : 'ja');
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'ja' && languageCode != 'en') {
      throw ArgumentError.value(languageCode, 'languageCode');
    }
    await ref
        .read(secureStoreProvider)
        .write(_languageStorageKey, languageCode);
    state = AsyncData(Locale(languageCode));
  }
}
