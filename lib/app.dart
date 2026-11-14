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
  /// GF-00100 — Initializes GorapeApp.
  const GorapeApp({super.key});

  /// GF-00101 — Builds the widget or value for GorapeApp.
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

/// GF-00001 — Restores the session and selects the login or authenticated shell.
class AuthGate extends ConsumerWidget {
  /// GF-00102 — Initializes AuthGate.
  const AuthGate({super.key});

  /// GF-00103 — Builds the widget or value for AuthGate.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // GF-02037 — Resolve platform, saved connection settings, and auth state.
    final platform = ref.watch(runtimePlatformProvider);
    final connection = ref.watch(connectionSettingsProvider);
    final auth = ref.watch(authControllerProvider);

    if (connection.isLoading && !connection.hasValue) {
      // GF-02038 — Keep the splash screen visible while settings are loading.
      return const _SplashScreen(label: '設定を読み込み中...');
    }
    if (connection.hasError && !connection.hasValue) {
      // GF-02039 — Surface settings errors with a retry action.
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorCard(
              error: connection.error!,
              onRetry: /* GF-00104 — Runs an inline callback in AuthGate.build. */
                  () => ref.invalidate(connectionSettingsProvider),
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
      // GF-02040 — Route restored or signed-in sessions to the app shell.
      return const AppShell();
    }

    if (auth.isLoading) {
      return _SplashScreen(
        label: auth.hasValue ? 'ログインしています...' : 'セッションを確認中...',
      );
    }

    final authSupport = ref.watch(authSupportProvider);
    // GF-02041 — Build the login screen with platform support and settings.
    return LoginScreen(
      settings: settings,
      platform: platform,
      support: ref.watch(platformSupportProvider),
      oidcSupported: authSupport.isSupported,
      loading: auth.isLoading,
      error: auth.hasError ? auth.error : null,
      unsupportedReason: authSupport.unsupportedReason,
      onLogin: /* GF-00105 — Runs an inline callback in AuthGate.build. */ () =>
          ref.read(authControllerProvider.notifier).signIn(),
      onAdminLogin: /* GF-00106 — Runs an inline callback in AuthGate.build. */
          () => ref
              .read(authControllerProvider.notifier)
              .signIn(forceLogin: true),
      onOpenSettings: /* GF-00107 — Runs an inline callback in AuthGate.build. */
          () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: /* GF-00108 — Runs an inline callback in AuthGate.build.callback. */
                    (_) => const SettingsScreen(fromLogin: true),
              ),
            );
          },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  /// GF-00109 — Initializes _SplashScreen.
  const _SplashScreen({required this.label});

  final String label;

  /// GF-00110 — Builds the widget or value for _SplashScreen.
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
