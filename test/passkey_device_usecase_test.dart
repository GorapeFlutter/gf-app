import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/entity/model/device.dart';
import 'package:gf_app/entity/model/platform.dart';
import 'package:gf_app/entity/model/platform_support.dart';
import 'package:gf_app/entity/request/passkey.dart';
import 'package:gf_app/entity/response/passkey.dart';
import 'package:gf_app/back/repository/passkey.dart';
import 'package:gf_app/back/repository/passkey_device.dart';
import 'package:gf_app/back/repository/platform.dart';
import 'package:gf_app/back/share/error.dart';
import 'package:gf_app/back/usecase/passkey_device.dart';

const _creationOptions = <String, dynamic>{
  'challenge': 'Y2hhbGxlbmdl',
  'rp': {'id': 'gorape.example', 'name': 'Gorape'},
  'user': {'id': 'dXNlci0x', 'name': 'user', 'displayName': 'User'},
  'attestation': 'direct',
};
const _requestOptions = <String, dynamic>{
  'challenge': 'Y2hhbGxlbmdl',
  'rpId': 'gorape.example',
  'userVerification': 'required',
};

class _Devices implements PasskeyDeviceRepository {
  _Devices({this.platform = 'android', this.browserUrl, this.browserApiOrigin});

  final String platform;
  final String? browserUrl;
  final String? browserApiOrigin;
  late final PasskeyRegistrationOptions registrationOptions =
      PasskeyRegistrationOptions(
        challengeId: 'registration-1',
        publicKey: _creationOptions,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        browserUrl: browserUrl,
        browserApiOrigin: browserApiOrigin,
      );
  late final PasskeyAuthenticationOptions authenticationOptions =
      PasskeyAuthenticationOptions(
        challengeId: 'proof-1',
        publicKey: _requestOptions,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        browserUrl: browserUrl,
        browserApiOrigin: browserApiOrigin,
      );
  PasskeyRegistrationVerifyRequest? registrationRequest;
  PasskeyAuthenticationVerifyRequest? authenticationRequest;
  var registrationOptionsCalls = 0;
  var authenticationOptionsCalls = 0;

  @override
  Future<PasskeyRegistrationOptions> createRegistrationOptions(
    String projectId, {
    required String platform,
    required String displayName,
  }) async {
    registrationOptionsCalls++;
    expect(projectId, 'project-1');
    expect(platform, this.platform);
    expect(displayName, 'Pixel');
    return registrationOptions;
  }

  @override
  Future<PasskeyRegistrationResult> verifyRegistration(
    String projectId,
    PasskeyRegistrationVerifyRequest request,
  ) async {
    registrationRequest = request;
    return PasskeyRegistrationResult(
      device: Device(
        id: 'device-1',
        projectId: projectId,
        ownerPrincipalId: 'principal-1',
        platform: request.platform,
        displayName: request.displayName,
        status: 'active',
        registeredAt: DateTime.utc(2026),
      ),
      attestationType: 'android-key',
      securityLevel: 'trusted_environment',
      verifierVersion: 'gorape-webauthn-v1',
    );
  }

  @override
  Future<PasskeyRegistrationResult> registrationResult(
    String projectId,
    String deviceId,
  ) async => _registrationResult(projectId, deviceId, platform, 'Pixel');

  @override
  Future<PasskeyAuthenticationOptions> createAuthenticationOptions(
    String projectId,
    String deviceId, {
    required String platform,
  }) async {
    authenticationOptionsCalls++;
    expect(projectId, 'project-1');
    expect(deviceId, 'device-1');
    expect(platform, this.platform);
    return authenticationOptions;
  }

  @override
  Future<void> verifyAuthentication(
    String projectId,
    String deviceId,
    PasskeyAuthenticationVerifyRequest request,
  ) async {
    authenticationRequest = request;
  }

  PasskeyRegistrationResult _registrationResult(
    String projectId,
    String deviceId,
    String devicePlatform,
    String displayName,
  ) => PasskeyRegistrationResult(
    device: Device(
      id: deviceId,
      projectId: projectId,
      ownerPrincipalId: 'principal-1',
      platform: devicePlatform,
      displayName: displayName,
      status: 'active',
      registeredAt: DateTime.utc(2026),
    ),
    attestationType: 'android-key',
    securityLevel: 'android_key_attested',
    verifierVersion: 'gorape-webauthn-v1',
  );
}

class _Passkeys implements PasskeyRepository {
  var registerCalls = 0;
  var authenticateCalls = 0;

  @override
  Future<Map<String, dynamic>> register(
    Map<String, dynamic> publicKeyOptions,
  ) async {
    registerCalls++;
    return const {
      'id': 'credential',
      'response': {'attestationObject': 'ao'},
    };
  }

  @override
  Future<Map<String, dynamic>> authenticate(
    Map<String, dynamic> publicKeyOptions,
  ) async {
    authenticateCalls++;
    return const {
      'id': 'credential',
      'response': {'signature': 'sig'},
    };
  }
}

class _BrowserPasskeys extends _Passkeys implements BrowserPasskeyRepository {
  var browserRegistrationCalls = 0;
  var browserAuthenticationCalls = 0;

  @override
  Future<Map<String, String>> registerInBrowser({
    required String browserUrl,
    required String browserApiOrigin,
    required String challengeId,
  }) async {
    browserRegistrationCalls++;
    expect(browserUrl, 'https://app.gorape.example/passkey-ceremony.html');
    expect(browserApiOrigin, 'https://api.gorape.example');
    expect(challengeId, 'registration-1');
    return const {'device_id': 'device-linux'};
  }

  @override
  Future<void> authenticateInBrowser({
    required String browserUrl,
    required String browserApiOrigin,
    required String challengeId,
  }) async {
    browserAuthenticationCalls++;
    expect(browserUrl, 'https://app.gorape.example/passkey-ceremony.html');
    expect(browserApiOrigin, 'https://api.gorape.example');
    expect(challengeId, 'proof-1');
  }
}

class _Platforms implements PlatformRepository {
  _Platforms(this.platform);
  final RuntimePlatform platform;

  @override
  RuntimePlatform current() => platform;

  @override
  PlatformSupport supportFor(RuntimePlatform platform) => PlatformSupport(
    platform: platform.wireName,
    oidcLogin: true,
    localKeyGeneration: false,
    attestationFlow: false,
    passkeyCeremony: platform != RuntimePlatform.unknown,
    note: '',
  );
}

void main() {
  group('PasskeyDeviceUsecaseImpl', () {
    test(
      'registers a Gorape RP credential and forwards attestation response',
      () async {
        final devices = _Devices();
        final passkeys = _Passkeys();
        final usecase = PasskeyDeviceUsecaseImpl(
          devices: devices,
          passkeys: passkeys,
          platforms: _Platforms(RuntimePlatform.android),
        );

        final result = await usecase.register(
          projectId: 'project-1',
          displayName: ' Pixel ',
        );

        expect(result.device.id, 'device-1');
        expect(result.attestationType, 'android-key');
        expect(devices.registrationRequest?.challengeId, 'registration-1');
        expect(devices.registrationRequest?.credential['id'], 'credential');
        expect(passkeys.registerCalls, 1);
      },
    );

    test('rejects empty names before requesting a challenge', () async {
      final devices = _Devices();
      final usecase = PasskeyDeviceUsecaseImpl(
        devices: devices,
        passkeys: _Passkeys(),
        platforms: _Platforms(RuntimePlatform.android),
      );

      await expectLater(
        usecase.register(projectId: 'project-1', displayName: '  '),
        throwsA(isA<ConfigurationException>()),
      );
      expect(devices.registrationOptionsCalls, 0);
    });

    test('uses the Gorape browser ceremony on Linux', () async {
      final devices = _Devices(
        platform: 'linux',
        browserUrl: 'https://app.gorape.example/passkey-ceremony.html',
        browserApiOrigin: 'https://api.gorape.example',
      );
      final passkeys = _BrowserPasskeys();
      final usecase = PasskeyDeviceUsecaseImpl(
        devices: devices,
        passkeys: passkeys,
        platforms: _Platforms(RuntimePlatform.linux),
      );

      final result = await usecase.register(
        projectId: 'project-1',
        displayName: 'Pixel',
      );

      expect(result.device.id, 'device-linux');
      expect(devices.registrationOptionsCalls, 1);
      expect(passkeys.registerCalls, 0);
      expect(passkeys.browserRegistrationCalls, 1);
      expect(devices.registrationRequest, isNull);
    });

    test('verifies passkey assertions for device possession', () async {
      final devices = _Devices();
      final passkeys = _Passkeys();
      final usecase = PasskeyDeviceUsecaseImpl(
        devices: devices,
        passkeys: passkeys,
        platforms: _Platforms(RuntimePlatform.android),
      );

      await usecase.provePossession(
        projectId: 'project-1',
        deviceId: 'device-1',
      );

      expect(devices.authenticationOptionsCalls, 1);
      expect(devices.authenticationRequest?.challengeId, 'proof-1');
      expect(devices.authenticationRequest?.credential['id'], 'credential');
      expect(passkeys.authenticateCalls, 1);
    });
  });
}
