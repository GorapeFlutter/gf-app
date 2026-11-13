import 'package:flutter/services.dart';

import '../repository/attestation.dart';
import '../repository/device.dart';
import '../repository/device_key.dart';
import '../entity/model/device.dart';
import '../entity/model/device_key.dart';
import '../entity/model/registered_device_key.dart';
import '../entity/request/device.dart';
import '../entity/response/device.dart';
import '../entity/response/attestation.dart';
import '../share/base64_url.dart';
import '../share/error.dart';
import '../share/random_id.dart';

abstract interface class DeviceUsecase {
  String get platform;
  Future<List<Device>> list(String projectId);
  Future<Device> get(String projectId, String deviceId);
  Future<DeviceKeyAvailability> availability();
  Future<RegisteredDeviceKey?> localKey(String projectId, String deviceId);
  Future<RegistrationResult> register({
    required String projectId,
    required String displayName,
    String? platform,
  });
  Future<RegisteredDeviceKey> provePossession({
    required String projectId,
    required String deviceId,
  });
  Future<void> revoke({required String projectId, required String deviceId});
}

final class DeviceUsecaseImpl implements DeviceUsecase {
  const DeviceUsecaseImpl({
    required DeviceRepository deviceRepository,
    required AttestationRepository attestationRepository,
    required DeviceKeyRepository keyRepository,
    required DeviceKeyStoreRepository keyStoreRepository,
  }) : _devices = deviceRepository,
       _attestations = attestationRepository,
       _keys = keyRepository,
       _keyStore = keyStoreRepository;

  final DeviceRepository _devices;
  final AttestationRepository _attestations;
  final DeviceKeyRepository _keys;
  final DeviceKeyStoreRepository _keyStore;

  @override
  String get platform => _keys.platform;

  @override
  Future<List<Device>> list(String projectId) => _devices.list(projectId);

  @override
  Future<Device> get(String projectId, String deviceId) =>
      _devices.get(projectId, deviceId);

  @override
  Future<DeviceKeyAvailability> availability() => _keys.availability();

  @override
  Future<RegisteredDeviceKey?> localKey(String projectId, String deviceId) =>
      _keyStore.load(projectId, deviceId);

  @override
  Future<RegistrationResult> register({
    required String projectId,
    required String displayName,
    String? platform,
  }) async {
    final effectivePlatform = platform ?? _keys.platform;
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      throw const ConfigurationException(
        'デバイス名を入力してください。',
        code: 'display_name_required',
      );
    }

    final availability = await _keys.availability();
    if (!availability.supported) {
      throw DeviceKeyUnsupportedException(
        availability.reason ?? 'このOSではOS保護鍵を生成できません。',
        platform: effectivePlatform,
        guidance: 'Android実機で実行してください。',
      );
    }

    final capabilities = await _attestations.capabilities(projectId);
    _ensureBackendSupports(capabilities, effectivePlatform);
    final challenge = await _devices.createRegistrationChallenge(
      projectId,
      platform: effectivePlatform,
    );
    if (challenge.isExpired) {
      throw const ChallengeException(
        '登録チャレンジの有効期限が切れています。もう一度お試しください。',
        code: 'challenge_expired',
      );
    }

    final keyIdentifier = 'gorape-$effectivePlatform-${randomId(12)}';
    GeneratedDeviceKey generated;
    try {
      generated = await _keys.generateKey(
        keyIdentifier: keyIdentifier,
        attestationChallenge: _decodeChallenge(challenge.challenge),
      );
    } on PlatformException catch (error) {
      throw DeviceKeyUnsupportedException(
        error.message ?? 'OS保護鍵を生成できませんでした。',
        platform: effectivePlatform,
        guidance: '端末の画面ロック設定とKeystoreの状態を確認してください。',
      );
    }

    try {
      final device = await _devices.verifyRegistration(
        projectId,
        RegistrationVerifyRequest(
          challengeId: challenge.challengeId,
          platform: effectivePlatform,
          displayName: trimmedName,
          publicKeyPem: generated.publicKeyPem,
          keyIdentifier: generated.keyIdentifier,
          algorithm: generated.algorithm,
          evidence: generated.evidence,
        ),
      );
      final record = RegisteredDeviceKey(
        projectId: projectId,
        deviceId: device.id,
        keyIdentifier: generated.keyIdentifier,
        algorithm: generated.algorithm,
        platform: effectivePlatform,
        displayName: trimmedName,
        createdAt: DateTime.now().toUtc(),
        securityLevel: generated.securityLevel,
      );
      await _keyStore.save(record);
      return RegistrationResult(
        device: device,
        key: record,
        securityLevel: generated.securityLevel,
      );
    } on Object {
      try {
        await _keys.deleteKey(generated.keyIdentifier);
      } on Object {
        // Best-effort orphan cleanup.
      }
      rethrow;
    }
  }

  @override
  Future<RegisteredDeviceKey> provePossession({
    required String projectId,
    required String deviceId,
  }) async {
    final record = await _keyStore.load(projectId, deviceId);
    if (record == null) {
      throw const DeviceKeyUnavailableException(
        'この端末には該当デバイスの秘密鍵がありません。',
        guidance: '別の端末で登録されたデバイスは署名できません。この端末で登録し直してください。',
      );
    }
    if (!await _keys.hasKey(record.keyIdentifier)) {
      throw const DeviceKeyUnavailableException(
        'OSキーストアに秘密鍵が見つかりません。',
        guidance: '端末のロック解除状態を確認するか、デバイスを再登録してください。',
      );
    }
    final challenge = await _devices.createProofChallenge(projectId, deviceId);
    if (challenge.isExpired) {
      throw const ChallengeException(
        '署名チャレンジの有効期限が切れています。もう一度お試しください。',
        code: 'challenge_expired',
      );
    }
    String signature;
    try {
      signature = await _keys.sign(
        keyIdentifier: record.keyIdentifier,
        data: _decodeChallenge(challenge.challenge),
      );
    } on PlatformException catch (error) {
      throw DeviceKeyUnavailableException(
        error.message ?? 'OS保護鍵で署名できませんでした。',
        guidance: 'Keystoreの鍵が無効化された可能性があります。再登録してください。',
      );
    }
    await _devices.verifyProof(
      projectId,
      deviceId,
      ProofVerifyRequest(
        challengeId: challenge.challengeId,
        signature: signature,
      ),
    );
    return record;
  }

  @override
  Future<void> revoke({
    required String projectId,
    required String deviceId,
  }) async {
    await _devices.revoke(projectId, deviceId);
    final record = await _keyStore.load(projectId, deviceId);
    if (record != null) {
      try {
        await _keys.deleteKey(record.keyIdentifier);
      } on Object {
        // Backend revocation already succeeded; cleanup remains best effort.
      }
      await _keyStore.delete(projectId, deviceId);
    }
  }

  void _ensureBackendSupports(
    AttestationCapabilities capabilities,
    String platform,
  ) {
    final status = capabilities.statusFor(platform);
    if (status == 'implemented') return;
    if (status == 'unconfigured') {
      throw const AttestationNotConfiguredException(
        'GorapeのAndroid Attestation検証が未設定です。',
        code: 'attestation_unconfigured',
        guidance:
            'Gorapeの Application.Server.Attestation.android_trust_anchors '
            'にGoogleのKey Attestation Root CAを設定し、capabilitiesが'
            'implementedを返すことを確認してください。',
      );
    }
    throw BackendAttestationUnsupportedException(
      'Gorapeバックエンドは $platform のAttestationを未対応として扱っています。',
      platform: platform,
      code: 'attestation_unsupported',
      guidance: '現行バックエンドではAndroid Key Attestationのみ実装されています。',
    );
  }

  Uint8List _decodeChallenge(String challenge) {
    try {
      final decoded = Base64Url.decode(challenge);
      if (decoded.isEmpty) throw const FormatException('empty challenge');
      return decoded;
    } on FormatException {
      throw const ChallengeException(
        'サーバーから返されたチャレンジをBase64urlとして解釈できませんでした。',
        code: 'invalid_challenge',
      );
    }
  }
}

DeviceUsecase newDeviceUsecase({
  required DeviceRepository deviceRepository,
  required AttestationRepository attestationRepository,
  required DeviceKeyRepository keyRepository,
  required DeviceKeyStoreRepository keyStoreRepository,
}) => DeviceUsecaseImpl(
  deviceRepository: deviceRepository,
  attestationRepository: attestationRepository,
  keyRepository: keyRepository,
  keyStoreRepository: keyStoreRepository,
);
