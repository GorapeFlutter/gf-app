import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/api/gorape_api_client.dart';
import 'package:gf_app/api/models/attestation.dart';
import 'package:gf_app/api/models/challenge.dart';
import 'package:gf_app/api/models/device.dart';
import 'package:gf_app/api/models/project.dart';
import 'package:gf_app/api/models/registration.dart';
import 'package:gf_app/core/errors/app_exception.dart';
import 'package:gf_app/core/storage/secure_store.dart';
import 'package:gf_app/core/utils/base64_url.dart';
import 'package:gf_app/device_keys/device_key_provider.dart';
import 'package:gf_app/device_keys/device_key_store.dart';
import 'package:gf_app/device_keys/device_proof_service.dart';
import 'package:gf_app/device_keys/device_registration_service.dart';

const _projectId = 'project-1';
const _challengeBytes = [1, 2, 3, 4, 5];

Challenge _challenge({bool expired = false}) {
  return Challenge(
    challengeId: 'challenge-1',
    challenge: Base64Url.encode(Uint8List.fromList(_challengeBytes)),
    expiresAt: expired
        ? DateTime.now().subtract(const Duration(minutes: 1))
        : DateTime.now().add(const Duration(minutes: 5)),
  );
}

Device _device() {
  return Device(
    id: 'device-1',
    projectId: _projectId,
    ownerPrincipalId: 'principal-1',
    platform: 'android',
    displayName: 'Pixel',
    status: 'active',
    registeredAt: DateTime.utc(2026, 1, 1),
  );
}

class FakeGorapeApi implements GorapeApi {
  AttestationCapabilities capabilities = const AttestationCapabilities({
    'android': 'implemented',
  });
  Challenge registrationChallenge = _challenge();
  Challenge proofChallenge = _challenge();
  Object? registrationError;
  Object? proofError;

  RegistrationVerifyRequest? registrationRequest;
  ProofVerifyRequest? proofRequest;
  final List<String> calls = <String>[];

  @override
  Future<AttestationCapabilities> attestationCapabilities(
    String projectId,
  ) async {
    calls.add('capabilities');
    return capabilities;
  }

  @override
  Future<Challenge> createRegistrationChallenge(
    String projectId, {
    required String platform,
  }) async {
    calls.add('registrationChallenge:$platform');
    return registrationChallenge;
  }

  @override
  Future<Challenge> createProofChallenge(
    String projectId,
    String deviceId,
  ) async {
    calls.add('proofChallenge');
    return proofChallenge;
  }

  @override
  Future<Device> verifyRegistration(
    String projectId,
    RegistrationVerifyRequest request,
  ) async {
    calls.add('verifyRegistration');
    registrationRequest = request;
    if (registrationError != null) throw registrationError!;
    return _device();
  }

  @override
  Future<void> verifyProof(
    String projectId,
    String deviceId,
    ProofVerifyRequest request,
  ) async {
    calls.add('verifyProof');
    proofRequest = request;
    if (proofError != null) throw proofError!;
  }

  @override
  Future<Map<String, dynamic>> health() async => const {};

  @override
  Future<List<Project>> listProjects() async => const [];

  @override
  Future<Project> getProject(String projectId) => throw UnimplementedError();

  @override
  Future<List<Device>> listDevices(String projectId) async => const [];

  @override
  Future<Device> getDevice(String projectId, String deviceId) =>
      throw UnimplementedError();

  @override
  Future<void> revokeDevice(String projectId, String deviceId) async {}

  @override
  Future<List<AttestationRecord>> attestations(
    String projectId,
    String deviceId,
  ) async => const [];
}

class FakeDeviceKeyProvider implements DeviceKeyProvider {
  bool supported = true;
  bool hasStoredKey = true;
  String? unsupportedReason;
  Uint8List? generatedWithChallenge;
  Uint8List? signedData;
  String? deletedKeyIdentifier;
  Object? generationError;

  @override
  String get platform => 'android';

  @override
  Future<DeviceKeyAvailability> availability() async {
    return DeviceKeyAvailability(
      supported: supported,
      hardwareBacked: true,
      attestationSupported: true,
      securityLevel: 'trusted_environment',
      reason: unsupportedReason,
    );
  }

  @override
  Future<GeneratedDeviceKey> generateKey({
    required String keyIdentifier,
    required Uint8List attestationChallenge,
  }) async {
    if (generationError != null) throw generationError!;
    generatedWithChallenge = attestationChallenge;
    return GeneratedDeviceKey(
      keyIdentifier: keyIdentifier,
      publicKeyPem: '-----BEGIN PUBLIC KEY-----\nkey\n-----END PUBLIC KEY-----',
      algorithm: 'ES256',
      securityLevel: 'trusted_environment',
      evidence: {
        'certificate_chain': ['leaf-pem', 'issuer-pem'],
      },
    );
  }

  @override
  Future<String> sign({
    required String keyIdentifier,
    required Uint8List data,
  }) async {
    signedData = data;
    return 'c2lnbmF0dXJl';
  }

  @override
  Future<bool> hasKey(String keyIdentifier) async => hasStoredKey;

  @override
  Future<void> deleteKey(String keyIdentifier) async {
    deletedKeyIdentifier = keyIdentifier;
  }
}

void main() {
  late FakeGorapeApi api;
  late FakeDeviceKeyProvider keys;
  late MemorySecureStore store;
  late DeviceKeyStore keyStore;

  setUp(() {
    api = FakeGorapeApi();
    keys = FakeDeviceKeyProvider();
    store = MemorySecureStore();
    keyStore = DeviceKeyStore(store);
  });

  DeviceRegistrationService registrationService() {
    return DeviceRegistrationService(
      api: api,
      keyProvider: keys,
      keyStore: keyStore,
    );
  }

  DeviceProofService proofService() {
    return DeviceProofService(api: api, keyProvider: keys, keyStore: keyStore);
  }

  group('DeviceRegistrationService', () {
    test('binds the raw challenge and submits leaf-first evidence', () async {
      final result = await registrationService().register(
        projectId: _projectId,
        displayName: ' Pixel ',
      );

      expect(api.calls, [
        'capabilities',
        'registrationChallenge:android',
        'verifyRegistration',
      ]);
      expect(keys.generatedWithChallenge, orderedEquals(_challengeBytes));

      final request = api.registrationRequest!;
      expect(request.challengeId, 'challenge-1');
      expect(request.displayName, 'Pixel');
      expect(request.platform, 'android');
      expect(request.algorithm, 'ES256');
      expect(request.evidence['certificate_chain'], ['leaf-pem', 'issuer-pem']);

      expect(result.device.id, 'device-1');
      expect(result.securityLevel, 'trusted_environment');
      final saved = await keyStore.load(_projectId, 'device-1');
      expect(saved, isNotNull);
      expect(saved!.keyIdentifier, request.keyIdentifier);
      expect(saved.platform, 'android');
    });

    test('rejects an unconfigured backend before generating a key', () async {
      api.capabilities = const AttestationCapabilities({
        'android': 'unconfigured',
      });

      await expectLater(
        registrationService().register(
          projectId: _projectId,
          displayName: 'Pixel',
        ),
        throwsA(
          isA<AttestationNotConfiguredException>().having(
            (error) => error.guidance,
            'guidance',
            contains('android_trust_anchors'),
          ),
        ),
      );
      expect(api.calls, ['capabilities']);
      expect(keys.generatedWithChallenge, isNull);
    });

    test('reports platforms the backend marks unsupported', () async {
      await expectLater(
        registrationService().register(
          projectId: _projectId,
          displayName: 'Surface',
          platform: 'windows',
        ),
        throwsA(
          isA<BackendAttestationUnsupportedException>().having(
            (error) => error.platform,
            'platform',
            'windows',
          ),
        ),
      );
      expect(api.calls, ['capabilities']);
    });

    test('rejects an expired challenge', () async {
      api.registrationChallenge = _challenge(expired: true);

      await expectLater(
        registrationService().register(
          projectId: _projectId,
          displayName: 'Pixel',
        ),
        throwsA(isA<ChallengeException>()),
      );
      expect(keys.generatedWithChallenge, isNull);
    });

    test('deletes the generated key when registration fails', () async {
      api.registrationError = const ApiException(
        'attestation rejected',
        statusCode: 422,
      );

      await expectLater(
        registrationService().register(
          projectId: _projectId,
          displayName: 'Pixel',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(keys.deletedKeyIdentifier, isNotNull);
      expect(keys.deletedKeyIdentifier, api.registrationRequest!.keyIdentifier);
      expect(await keyStore.load(_projectId, 'device-1'), isNull);
    });

    test(
      'refuses to register when the OS key provider is unavailable',
      () async {
        keys.supported = false;
        keys.unsupportedReason = 'No hardware Keystore';

        await expectLater(
          registrationService().register(
            projectId: _projectId,
            displayName: 'Pixel',
          ),
          throwsA(
            isA<DeviceKeyUnsupportedException>().having(
              (error) => error.platform,
              'platform',
              'android',
            ),
          ),
        );
        expect(api.calls, isEmpty);
      },
    );
  });

  group('DeviceProofService', () {
    Future<void> saveKey() {
      return keyStore.save(
        RegisteredDeviceKey(
          projectId: _projectId,
          deviceId: 'device-1',
          keyIdentifier: 'gorape-android-key',
          algorithm: 'ES256',
          platform: 'android',
          displayName: 'Pixel',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
    }

    test('signs the raw challenge bytes and sends Base64url', () async {
      await saveKey();

      final record = await proofService().verifyPossession(
        projectId: _projectId,
        deviceId: 'device-1',
      );

      expect(record.keyIdentifier, 'gorape-android-key');
      expect(keys.signedData, orderedEquals(_challengeBytes));
      expect(api.proofRequest!.challengeId, 'challenge-1');
      expect(api.proofRequest!.signature, 'c2lnbmF0dXJl');
    });

    test('requires a locally stored key for the device', () async {
      await expectLater(
        proofService().verifyPossession(
          projectId: _projectId,
          deviceId: 'device-1',
        ),
        throwsA(isA<DeviceKeyUnavailableException>()),
      );
      expect(api.calls, isEmpty);
    });

    test('fails when the OS key no longer exists', () async {
      await saveKey();
      keys.hasStoredKey = false;

      await expectLater(
        proofService().verifyPossession(
          projectId: _projectId,
          deviceId: 'device-1',
        ),
        throwsA(isA<DeviceKeyUnavailableException>()),
      );
      expect(api.calls, isEmpty);
      expect(keys.signedData, isNull);
    });
  });
}
