import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/config/connection.dart';
import 'package:gf_app/entity/model/connection.dart';
import 'package:gf_app/entity/model/platform.dart';
import 'package:gf_app/repository/platform.dart';
import 'package:gf_app/ui/screens/login_screen.dart';
import 'package:gf_app/ui/widgets/common.dart';

void main() {
  final settings = newConnectionConfig().defaultsFor(RuntimePlatform.android);

  Future<void> pumpLogin(
    WidgetTester tester, {
    required bool oidcSupported,
    required VoidCallback onLogin,
    VoidCallback? onAdminLogin,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        supportedLocales: const [Locale('ja'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: LoginScreen(
          settings: settings,
          platform: RuntimePlatform.android,
          support: newPlatformRepository().supportFor(RuntimePlatform.android),
          oidcSupported: oidcSupported,
          loading: false,
          onLogin: onLogin,
          onAdminLogin: onAdminLogin ?? onLogin,
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
    var adminLogins = 0;
    await pumpLogin(
      tester,
      oidcSupported: true,
      onLogin: () => logins++,
      onAdminLogin: () => adminLogins++,
    );

    expect(find.text('GF'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/gorape/brand/gorape_header.png',
      ),
      findsOneWidget,
    );
    expect(find.text('http://10.0.2.2:8000'), findsOneWidget);
    expect(find.text('http://localhost:8080/realms/gorape'), findsOneWidget);
    expect(find.text(ConnectionSettings.flutterRedirectUri), findsOneWidget);
    expect(find.textContaining('ID TokenはAPI認証情報として使用しません'), findsOneWidget);

    await tester.ensureVisible(find.text('Keycloakでログイン'));
    await tester.tap(find.text('Keycloakでログイン'));
    await tester.pump();

    expect(logins, 1);
    await tester.ensureVisible(find.text('管理者ログイン'));
    await tester.tap(find.text('管理者ログイン'));
    await tester.pump();
    expect(adminLogins, 1);
    expect(find.textContaining('管理者機能を使う場合'), findsOneWidget);
  });

  testWidgets('shows the Keycloak registration URL', (tester) async {
    await pumpLogin(tester, oidcSupported: true, onLogin: () {});

    await tester.ensureVisible(find.text('アカウント登録'));
    await tester.tap(find.text('アカウント登録'));
    await tester.pumpAndSettle();

    expect(find.text(LoginScreen.registrationUrl), findsOneWidget);
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
