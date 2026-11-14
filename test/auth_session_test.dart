import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/entity/model/auth_session.dart';
import 'package:gf_app/entity/model/auth_tokens.dart';

String _tokenWithAmr(List<String> amr) {
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({'amr': amr})))
      .replaceAll('=', '');
  return 'header.$payload.signature';
}

void main() {
  test('only a passkey AMR marks the session as passkey-authenticated', () {
    expect(
      AuthSession(
        tokens: AuthTokens(accessToken: _tokenWithAmr(['passkey'])),
      ).isPasskeyAuthenticated,
      isTrue,
    );
    expect(
      AuthSession(
        tokens: AuthTokens(accessToken: _tokenWithAmr(['pwd'])),
      ).isPasskeyAuthenticated,
      isFalse,
    );
    expect(
      AuthSession(
        tokens: const AuthTokens(accessToken: 'opaque-token'),
      ).isPasskeyAuthenticated,
      isFalse,
    );
  });
}
