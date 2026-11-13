import 'package:flutter/material.dart' hide Text;
import 'l10n/app_text.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controller/providers.dart';
import 'ui/app_theme.dart';
import 'ui/screens/app_shell.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/widgets/common.dart';

class GorapeApp extends ConsumerWidget {
  const GorapeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider).value ?? const Locale('ja');
    return MaterialApp(
      title: 'GF',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('ja'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = ref.watch(runtimePlatformProvider);
    final connection = ref.watch(connectionSettingsProvider);
    final auth = ref.watch(authControllerProvider);

    if (connection.isLoading && !connection.hasValue) {
      return const _SplashScreen(label: '設定を読み込み中...');
    }
    if (connection.hasError && !connection.hasValue) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorCard(
              error: connection.error!,
              onRetry: () => ref.invalidate(connectionSettingsProvider),
            ),
          ),
        ),
      );
    }

    final settings =
        connection.value ??
        ref.watch(connectionConfigProvider).defaultsFromEnvironment(platform);
    final session = auth.value;

    if (session != null) {
      return const AppShell();
    }

    if (auth.isLoading) {
      return _SplashScreen(
        label: auth.hasValue ? 'ログインしています...' : 'セッションを確認中...',
      );
    }

    final authSupport = ref.watch(authSupportProvider);
    return LoginScreen(
      settings: settings,
      platform: platform,
      support: ref.watch(platformSupportProvider),
      oidcSupported: authSupport.isSupported,
      loading: auth.isLoading,
      error: auth.hasError ? auth.error : null,
      unsupportedReason: authSupport.unsupportedReason,
      onLogin: () => ref.read(authControllerProvider.notifier).signIn(),
      onAdminLogin: () =>
          ref.read(authControllerProvider.notifier).signIn(forceLogin: true),
      onOpenSettings: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const SettingsScreen(fromLogin: true),
          ),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                'assets/gorape/brand/main_logo_symbol.png',
                width: 40,
                height: 40,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            AppText(label),
          ],
        ),
      ),
    );
  }
}
