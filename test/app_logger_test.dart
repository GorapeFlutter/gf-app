import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/back/share/logger.dart';
import 'package:gf_app/back/share/mcode.dart';

void main() {
  test('emits structured MCode records and redacts secret-shaped fields', () {
    final records = <String>[];
    final logger = AppLogger(
      config: const AppLoggerConfig(enabled: true),
      sink: (message, _, _) => records.add(message),
    );

    logger.info(
      AppMCodes.apiResponseReceived,
      fields: {
        'method': 'POST',
        'status_code': 201,
        'authorization': 'Bearer actual-token-value',
        'credential': {'signature': 'actual-signature-value'},
        'url': 'https://api.example.test/?access_token=query-token-value',
        'diagnostic':
            'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTYifQ.signature-value',
        'pem':
            '-----BEGIN PRIVATE KEY-----private-material-----END PRIVATE KEY-----',
      },
    );

    expect(records, hasLength(1));
    final record = jsonDecode(records.single) as Map<String, dynamic>;
    expect(
      record['code'],
      AppMCodes.apiResponseReceived.padded(AppMCodes.maxCodeLength),
    );
    expect(record['fields']['method'], 'POST');
    expect(record['fields']['status_code'], 201);
    expect(record['fields']['authorization'], '[REDACTED]');
    expect(record['fields']['credential'], '[REDACTED]');
    expect(records.single, isNot(contains('actual-token-value')));
    expect(records.single, isNot(contains('actual-signature-value')));
    expect(records.single, isNot(contains('query-token-value')));
    expect(records.single, isNot(contains('eyJhbGci')));
    expect(records.single, isNot(contains('private-material')));
  });

  test('filters records below the configured minimum level', () {
    final records = <String>[];
    final logger = AppLogger(
      config: const AppLoggerConfig(
        enabled: true,
        minimumLevel: AppLogLevel.warning,
      ),
      sink: (message, _, _) => records.add(message),
    );

    logger.debug(AppMCodes.apiRequestStarted);
    logger.warning(AppMCodes.apiRequestFailed);

    expect(records, hasLength(1));
    expect(records.single, contains(AppMCodes.apiRequestFailed.code));
  });

  test('redacts WebAuthn response fields in arbitrary nested payloads', () {
    final records = <String>[];
    final logger = AppLogger(
      config: const AppLoggerConfig(enabled: true),
      sink: (message, _, _) => records.add(message),
    );

    logger.debug(
      AppMCodes.passkeyProviderCompleted,
      fields: {
        'diagnostics': {
          'clientDataJSON': 'challenge-value',
          'authenticatorData': 'authenticator-value',
          'unrelated': 'safe',
        },
      },
    );

    expect(records.single, isNot(contains('challenge-value')));
    expect(records.single, isNot(contains('authenticator-value')));
    expect(records.single, contains('safe'));
  });

  test('MCode catalog has padded stable codes', () {
    expect(AppMCodes.maxCodeLength, greaterThanOrEqualTo(7));
    expect(
      AppMCodes.all.map((code) => code.code).toSet(),
      hasLength(AppMCodes.all.length),
    );
    expect(
      AppMCodes.apiRequestStarted.padded(AppMCodes.maxCodeLength).trim(),
      'FAPI001',
    );
  });

  test('redacts identifiers from API paths but preserves endpoint names', () {
    expect(
      AppLogger.redactPath('/v1/projects/tenant-a/devices/device-b/passkeys'),
      '/v1/projects/{id}/devices/{id}/passkeys',
    );
  });
}
