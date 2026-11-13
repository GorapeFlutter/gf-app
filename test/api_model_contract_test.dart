import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/entity/model/attestation.dart';
import 'package:gf_app/entity/model/device.dart';

void main() {
  test('Device parses the backend owner_id field', () {
    final device = Device.fromJson({
      'id': 'device-1',
      'project_id': 'project-1',
      'owner_id': 'principal-1',
      'platform': 'android',
      'display_name': 'Pixel',
      'status': 'active',
      'registered_at': '2026-11-14T00:00:00Z',
    });

    expect(device.ownerPrincipalId, 'principal-1');
  });

  test('AttestationRecord parses the backend key_id field', () {
    final attestation = AttestationRecord.fromJson({
      'id': 'attestation-1',
      'project_id': 'project-1',
      'key_id': 'device-key-1',
      'attestation_type': 'android-key-attestation',
      'security_level': 'strongbox',
      'verification_status': 'verified',
      'verifier_version': 'gorape-android-v1',
      'verified_at': '2026-11-14T00:00:00Z',
    });

    expect(attestation.deviceKeyId, 'device-key-1');
  });
}
