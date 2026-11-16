import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/back/repository/credential_provider.dart';
import 'package:gf_app/entity/model/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    AndroidCredentialProviderRepository.channelName,
  );

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'reads Android provider registration without claiming enabled state',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'status');
            return {
              'apiLevel': 37,
              'supported': true,
              'serviceRegistered': true,
            };
          });

      final status = await AndroidCredentialProviderRepository().status();

      expect(status.apiLevel, 37);
      expect(status.supported, isTrue);
      expect(status.serviceRegistered, isTrue);
    },
  );

  test(
    'opens the Android system settings through the method channel',
    () async {
      var opened = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'openSettings');
            opened = true;
            return true;
          });

      await AndroidCredentialProviderRepository().openSettings();

      expect(opened, isTrue);
    },
  );

  test('uses a non-Android repository on other platforms', () async {
    final repository = newCredentialProviderRepository(RuntimePlatform.ios);
    final status = await repository.status();

    expect(status.supported, isFalse);
    expect(status.serviceRegistered, isFalse);
    expect(repository.openSettings(), throwsUnsupportedError);
  });
}
