import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gf_app/back/repository/device_key.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android Keystore creates a hardware-attested probe key', (
    tester,
  ) async {
    final repository = AndroidDeviceKeyRepository();
    final availability = await repository.availability();

    expect(availability.supported, isTrue, reason: availability.reason);
    expect(availability.hardwareBacked, isTrue, reason: availability.reason);
    expect(availability.attestationSupported, isTrue);

    final keyIdentifier =
        'gorape-attestation-probe-${DateTime.now().microsecondsSinceEpoch}';
    final challenge = Uint8List.fromList(
      List<int>.generate(32, (_) => Random.secure().nextInt(256)),
    );

    try {
      final generated = await repository.generateKey(
        keyIdentifier: keyIdentifier,
        attestationChallenge: challenge,
      );
      final chain = generated.evidence['certificate_chain'];

      expect(generated.publicKeyPem, isNotEmpty);
      expect(chain, isA<List<String>>());
      expect((chain as List<String>), isNotEmpty);
      expect(
        generated.securityLevel,
        anyOf('strongbox', 'trusted_environment'),
      );
      expect(await repository.hasKey(keyIdentifier), isTrue);

      // The integration test reports only non-secret capability metadata.
      // It never prints or transfers the certificate chain or private key.
      // ignore: avoid_print
      print(
        'Android Keystore attestation probe: '
        'securityLevel=${generated.securityLevel}, chainLength=${chain.length}',
      );
      if (const bool.fromEnvironment('DUMP_ANDROID_ATTESTATION_PROBE')) {
        // Diagnostic-only output is redirected to an ignored temporary log by
        // the test runner; the private key never leaves Keystore.
        // ignore: avoid_print
        print('ANDROID_ATTESTATION_PROBE_JSON_BEGIN');
        // ignore: avoid_print
        print(
          jsonEncode({
            'challenge': base64Url.encode(challenge).replaceAll('=', ''),
            'public_key_pem': generated.publicKeyPem,
            'evidence': generated.evidence,
          }),
        );
        // ignore: avoid_print
        print('ANDROID_ATTESTATION_PROBE_JSON_END');
      }
    } finally {
      await repository.deleteKey(keyIdentifier);
    }

    expect(await repository.hasKey(keyIdentifier), isFalse);
  });
}
