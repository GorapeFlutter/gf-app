import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/connection_settings.dart';
import 'state/auth_controller.dart';
import 'ui/app_theme.dart';
import 'ui/screens/app_shell.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/widgets/common.dart';

class GorapeApp extends StatelessWidget {
  const GorapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gorape Device Trust',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
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
        ConnectionSettings.defaultsFromEnvironment(platform);
    final session = auth.value;

    if (session != null) {
      return const AppShell();
    }

    if (auth.isLoading) {
      return _SplashScreen(
        label: auth.hasValue ? 'ログインしています...' : 'セッションを確認中...',
      );
    }

    final oidc = ref.watch(oidcServiceProvider);
    return LoginScreen(
      settings: settings,
      platform: platform,
      oidcSupported: oidc.isSupported,
      loading: auth.isLoading,
      error: auth.hasError ? auth.error : null,
      unsupportedReason: oidc.unsupportedReason,
      onLogin: () => ref.read(authControllerProvider.notifier).signIn(),
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
              child: Icon(
                Icons.shield_outlined,
                size: 40,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}
