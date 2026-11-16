import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/back/repository/platform.dart';
import 'package:gf_app/entity/model/platform.dart';

void main() {
  const repository = PlatformRepositoryImpl();

  test('Windows supports passkeys and CNG/TPM local keys', () {
    final support = repository.supportFor(RuntimePlatform.windows);
    expect(support.platform, 'windows');
    expect(support.oidcLogin, isTrue);
    expect(support.passkeyCeremony, isTrue);
    expect(support.localKeyGeneration, isTrue);
    expect(support.attestationFlow, isFalse);
  });

  test('Android, iOS, and macOS remain passkey-capable', () {
    for (final platform in [
      RuntimePlatform.android,
      RuntimePlatform.ios,
      RuntimePlatform.macos,
    ]) {
      final support = repository.supportFor(platform);
      expect(support.passkeyCeremony, isTrue, reason: platform.wireName);
      expect(support.oidcLogin, isTrue, reason: platform.wireName);
    }
  });
}
