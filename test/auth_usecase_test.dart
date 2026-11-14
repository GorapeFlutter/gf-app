import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/entity/model/auth_session.dart';
import 'package:gf_app/entity/model/auth_tokens.dart';
import 'package:gf_app/back/repository/auth.dart';
import 'package:gf_app/back/repository/secure_store.dart';
import 'package:gf_app/back/share/error.dart';
import 'package:gf_app/back/usecase/auth.dart';

String _accessToken(List<String> amr) {
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({'amr': amr})))
      .replaceAll('=', '');
  return 'header.$payload.signature';
}

final class _AuthRepository implements AuthRepository {
  _AuthRepository(this.tokens, {this.failSignOut = false});
  final AuthTokens tokens;
  final bool failSignOut;

  @override
  bool get isSupported => true;

  @override
  String? get unsupportedReason => null;

  @override
  Future<AuthTokens> signIn({
    bool forceLogin = false,
    bool requirePasskey = false,
  }) async => tokens;

  @override
  Future<bool> registerPasskey() async => true;

  @override
  Future<AuthTokens> refresh(AuthTokens tokens) async => this.tokens;

  @override
  Future<void> signOut(AuthTokens tokens) async {
    if (failSignOut) {
      throw const AuthException('remote logout failed', code: 'logout_failed');
    }
  }
}

void main() {
  test('passkey-only login does not persist a password-only token', () async {
    final store = MemorySecureStore();
    final usecase = AuthUsecaseImpl(
      _AuthRepository(AuthTokens(accessToken: _accessToken(['pwd']))),
      store,
    );

    await expectLater(
      usecase.signIn(requirePasskey: true),
      throwsA(
        isA<AuthException>().having(
          (error) => error.code,
          'code',
          'passkey_authentication_required',
        ),
      ),
    );
    expect(store.values, isEmpty);
  });

  test(
    'passkey-only login persists a token carrying the passkey AMR',
    () async {
      final store = MemorySecureStore();
      final token = AuthTokens(accessToken: _accessToken(['passkey']));
      final usecase = AuthUsecaseImpl(_AuthRepository(token), store);

      final session = await usecase.signIn(requirePasskey: true);

      expect(session.isPasskeyAuthenticated, isTrue);
      expect(store.values[AuthUsecaseImpl.tokenStorageKey], token.encode());
    },
  );

  test(
    'local sign-out clears credentials when Keycloak logout fails',
    () async {
      final store = MemorySecureStore();
      final token = AuthTokens(accessToken: _accessToken(['passkey']));
      final usecase = AuthUsecaseImpl(
        _AuthRepository(token, failSignOut: true),
        store,
      );
      await store.write(AuthUsecaseImpl.tokenStorageKey, token.encode());

      await usecase.signOut(AuthSession(tokens: token));

      expect(store.values, isEmpty);
    },
  );
}
