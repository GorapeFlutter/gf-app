import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android Credential Provider returns a Gorape WebAuthn credential',
    (tester) async {
      final random = Random.secure();
      String b64url(List<int> bytes) =>
          base64Url.encode(bytes).replaceAll('=', '');
      final request = RegisterRequestType.fromJson({
        'challenge': b64url(List<int>.generate(32, (_) => random.nextInt(256))),
        'rp': {'id': 'gorapeflutter.site', 'name': 'Gorape'},
        'user': {
          'id': b64url(List<int>.generate(32, (_) => random.nextInt(256))),
          'name': 'credential-provider-poc',
          'displayName': 'Credential Provider PoC',
        },
        'pubKeyCredParams': [
          {'type': 'public-key', 'alg': -7},
        ],
        'timeout': 120000,
        'attestation': 'direct',
        'authenticatorSelection': {
          'authenticatorAttachment': 'platform',
          'residentKey': 'required',
          'requireResidentKey': true,
          'userVerification': 'required',
        },
        'excludeCredentials': <Map<String, dynamic>>[],
      });

      final response = await PasskeyAuthenticator().register(request);
      expect(response.id, isNotEmpty);
      expect(response.clientDataJSON, isNotEmpty);
      expect(response.attestationObject, isNotEmpty);
      expect(response.transports, contains('internal'));

      if (const bool.fromEnvironment('DUMP_CREDENTIAL_PROVIDER_RESPONSE')) {
        // Diagnostic response contains only public WebAuthn/attestation data.
        // Redirect the test log to a local temporary file; never print key bytes.
        // ignore: avoid_print
        print('CREDENTIAL_PROVIDER_RESPONSE_BEGIN');
        // ignore: avoid_print
        print(response.toJsonString());
        // ignore: avoid_print
        print('CREDENTIAL_PROVIDER_RESPONSE_END');
      }
    },
  );
}
