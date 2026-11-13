import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/core/config/connection_settings.dart';
import 'package:gf_app/core/config/runtime_platform.dart';
import 'package:gf_app/ui/screens/login_screen.dart';
import 'package:gf_app/ui/widgets/common.dart';

void main() {
  final settings = ConnectionSettings.defaultsFor(RuntimePlatform.android);

  Future<void> pumpLogin(
    WidgetTester tester, {
    required bool oidcSupported,
    required VoidCallback onLogin,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          settings: settings,
          platform: RuntimePlatform.android,
          oidcSupported: oidcSupported,
          loading: false,
          onLogin: onLogin,
          onOpenSettings: () {},
          unsupportedReason: oidcSupported ? null : 'テスト用の未対応理由',
        ),
      ),
    );
  }

  testWidgets('shows connection details and starts Keycloak login', (
    tester,
  ) async {
    var logins = 0;
    await pumpLogin(tester, oidcSupported: true, onLogin: () => logins++);

    expect(find.text('Gorape Device Trust'), findsOneWidget);
    expect(find.text('http://10.0.2.2:8000'), findsOneWidget);
    expect(find.text('http://localhost:8080/realms/gorape'), findsOneWidget);
    expect(find.text(ConnectionSettings.flutterRedirectUri), findsOneWidget);
    expect(find.textContaining('ID TokenはAPI認証情報として使用しません'), findsOneWidget);

    await tester.ensureVisible(find.text('Keycloakでログイン'));
    await tester.tap(find.text('Keycloakでログイン'));
    await tester.pump();

    expect(logins, 1);
  });

  testWidgets('disables login and explains unsupported platforms', (
    tester,
  ) async {
    await pumpLogin(
      tester,
      oidcSupported: false,
      onLogin: () => fail('login must not start'),
    );

    expect(find.text('Androidではログイン未対応です'), findsOneWidget);
    expect(find.text('テスト用の未対応理由'), findsOneWidget);

    final button = tester
        .widgetList<FilledButton>(
          find.byWidgetPredicate((widget) => widget is FilledButton),
        )
        .single;
    expect(button.onPressed, isNull);
    expect(find.byType(ErrorCard), findsNothing);
  });
}
