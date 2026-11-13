import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/controller/base.dart';
import 'package:gf_app/controller/language.dart';
import 'package:gf_app/l10n/app_text.dart';
import 'package:gf_app/repository/secure_store.dart';
import 'package:gf_app/ui/screens/settings_screen.dart';

void main() {
  test(
    'language preference defaults to Japanese and persists changes',
    () async {
      final store = MemorySecureStore();
      final container = ProviderContainer(
        overrides: [secureStoreProvider.overrideWith((ref) => store)],
      );
      addTearDown(container.dispose);

      expect(await container.read(languageProvider.future), const Locale('ja'));

      await container.read(languageProvider.notifier).setLanguage('en');

      expect(container.read(languageProvider).value, const Locale('en'));
      expect(store.values['gf_app.language'], 'en');
    },
  );

  testWidgets('AppText uses the selected English locale', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: [Locale('ja'), Locale('en')],
        home: Scaffold(body: AppText('デバイス')),
      ),
    );

    expect(find.text('Devices'), findsOneWidget);
  });

  testWidgets('language can be changed from Settings', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStoreProvider.overrideWith((ref) => MemorySecureStore()),
        ],
        child: const _LocalizedSettingsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('表示言語'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    expect(find.text('Display language'), findsOneWidget);
    expect(find.text('Connection settings'), findsWidgets);
  });
}

class _LocalizedSettingsApp extends ConsumerWidget {
  const _LocalizedSettingsApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider).value ?? const Locale('ja');
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ja'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SettingsScreen(),
    );
  }
}
