import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/core/storage/secure_store.dart';
import 'package:gf_app/policy/device_policy.dart';

void main() {
  group('LocalDevicePolicy', () {
    test('round-trips on-device policy preferences', () {
      const policy = LocalDevicePolicy(
        allowDevicesWithoutAttestation: true,
        requireProofAfterLogin: false,
        passkeyStrategy: PasskeyStrategy.sharedPasskey,
      );
      final decoded = LocalDevicePolicy.decode(policy.encode());

      expect(decoded.allowDevicesWithoutAttestation, isTrue);
      expect(decoded.requireProofAfterLogin, isFalse);
      expect(decoded.passkeyStrategy, PasskeyStrategy.sharedPasskey);
    });

    test('falls back to safe defaults for unknown values', () {
      final decoded = LocalDevicePolicy.fromJson({
        'passkey_strategy': 'future-value',
      });

      expect(decoded.passkeyStrategy, PasskeyStrategy.dedicatedDeviceKey);
      expect(decoded.requireProofAfterLogin, isTrue);
      expect(decoded.allowDevicesWithoutAttestation, isFalse);
    });

    test('repository stores values in the secure store', () async {
      final store = MemorySecureStore();
      final repository = DevicePolicyRepository(store);

      expect((await repository.load()).requireProofAfterLogin, isTrue);

      await repository.save(
        const LocalDevicePolicy(requireProofAfterLogin: false),
      );

      final reloaded = await DevicePolicyRepository(store).load();
      expect(reloaded.requireProofAfterLogin, isFalse);
      expect(repository.capabilities.backendSupported, isFalse);
      expect(repository.capabilities.reason, contains('OpenAPI'));
    });
  });
}
