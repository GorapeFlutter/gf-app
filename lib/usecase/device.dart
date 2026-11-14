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
  /// GF-01073 — Computes DeviceUsecase.platform.
  String get platform;

  /// GF-01074 — Handles list in DeviceUsecase.
  Future<List<Device>> list(String projectId);

  /// GF-01075 — Handles get in DeviceUsecase.
  Future<Device> get(String projectId, String deviceId);

  /// GF-01076 — Handles availability in DeviceUsecase.
  Future<DeviceKeyAvailability> availability();

  /// GF-01077 — Handles local key in DeviceUsecase.
  Future<RegisteredDeviceKey?> localKey(String projectId, String deviceId);

  /// GF-01078 — Handles register in DeviceUsecase.
  Future<RegistrationResult> register({
    required String projectId,
    required String displayName,
    String? platform,
  });

  /// GF-01079 — Handles prove possession in DeviceUsecase.
  Future<RegisteredDeviceKey> provePossession({
    required String projectId,
    required String deviceId,
  });

  /// GF-01080 — Handles revoke in DeviceUsecase.
  Future<void> revoke({required String projectId, required String deviceId});
}

final class DeviceUsecaseImpl implements DeviceUsecase {
  /// GF-01081 — Initializes DeviceUsecaseImpl.
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

  /// GF-01082 — Computes DeviceUsecaseImpl.platform.
  @override
  String get platform => _keys.platform;

  /// GF-01083 — Handles list in DeviceUsecaseImpl.
  @override
  Future<List<Device>> list(String projectId) => _devices.list(projectId);

  /// GF-01084 — Handles get in DeviceUsecaseImpl.
  @override
  Future<Device> get(String projectId, String deviceId) =>
      _devices.get(projectId, deviceId);

  /// GF-01085 — Handles availability in DeviceUsecaseImpl.
  @override
  Future<DeviceKeyAvailability> availability() => _keys.availability();

  /// GF-01086 — Handles local key in DeviceUsecaseImpl.
  @override
  Future<RegisteredDeviceKey?> localKey(String projectId, String deviceId) =>
      _keyStore.load(projectId, deviceId);

  /// GF-01087 — Handles register in DeviceUsecaseImpl.
  /// GF-00005 — Orchestrates challenge, key attestation, verification, and storage.
  @override
  Future<RegistrationResult> register({
    required String projectId,
    required String displayName,
    String? platform,
  }) async {
    // GF-02023 — Normalize and validate the display name before device work.
    final effectivePlatform = platform ?? _keys.platform;
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      throw const ConfigurationException(
        'デバイス名を入力してください。',
        code: 'display_name_required',
      );
    }

    // GF-02024 — Check whether this platform can create an attested key.
    final availability = await _keys.availability();
    if (!availability.supported) {
      throw DeviceKeyUnsupportedException(
        availability.reason ?? 'このOSではOS保護鍵を生成できません。',
        platform: effectivePlatform,
        guidance: 'Android実機で実行してください。',
      );
    }

    // GF-02025 — Require a configured backend verifier before issuing a challenge.
    final capabilities = await _attestations.capabilities(projectId);
    _ensureBackendSupports(capabilities, effectivePlatform);
    // GF-02026 — Request a single-use registration challenge from Gorape.
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

    // GF-02027 — Bind the decoded challenge to a newly generated OS key.
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
      // GF-02028 — Submit the public key and attestation evidence for verification.
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
      // GF-02029 — Persist the local key alias only after server verification.
      await _keyStore.save(record);
      return RegistrationResult(
        device: device,
        key: record,
        securityLevel: generated.securityLevel,
      );
    } on Object {
      // GF-02030 — Remove the generated key if registration does not complete.
      try {
        await _keys.deleteKey(generated.keyIdentifier);
      } on Object {
        // Best-effort orphan cleanup.
      }
      rethrow;
    }
  }

  /// GF-01088 — Handles prove possession in DeviceUsecaseImpl.
  /// GF-00006 — Signs a fresh server challenge with the registered device key.
  @override
  Future<RegisteredDeviceKey> provePossession({
    required String projectId,
    required String deviceId,
  }) async {
    // GF-02031 — Load and verify that this device owns the registered private key.
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
    // GF-02032 — Request a fresh proof challenge and reject expired challenges.
    final challenge = await _devices.createProofChallenge(projectId, deviceId);
    if (challenge.isExpired) {
      throw const ChallengeException(
        '署名チャレンジの有効期限が切れています。もう一度お試しください。',
        code: 'challenge_expired',
      );
    }
    String signature;
    try {
      // GF-02033 — Sign the raw challenge bytes inside the OS key store.
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
    // GF-02034 — Submit the challenge reference and signature for verification.
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

  /// GF-01089 — Handles revoke in DeviceUsecaseImpl.
  /// GF-00007 — Revokes the server record before best-effort local key cleanup.
  @override
  Future<void> revoke({
    required String projectId,
    required String deviceId,
  }) async {
    // GF-02035 — Revoke the authoritative server-side device record first.
    await _devices.revoke(projectId, deviceId);
    final record = await _keyStore.load(projectId, deviceId);
    if (record != null) {
      // GF-02036 — Best-effort delete the OS key, then remove its local record.
      try {
        await _keys.deleteKey(record.keyIdentifier);
      } on Object {
        // Backend revocation already succeeded; cleanup remains best effort.
      }
      await _keyStore.delete(projectId, deviceId);
    }
  }

  /// GF-01090 — Handles ensure backend supports in DeviceUsecaseImpl.
  void _ensureBackendSupports(
    AttestationCapabilities capabilities,
    String platform,
  ) {
    // GF-02164 — Accept only the implemented verifier state for this platform.
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

  /// GF-01091 — Handles decode challenge in DeviceUsecaseImpl.
  Uint8List _decodeChallenge(String challenge) {
    try {
      // GF-02165 — Decode and reject empty challenge bytes.
      final decoded = Base64Url.decode(challenge);
      if (decoded.isEmpty) throw const FormatException('empty challenge');
      return decoded;
    } on FormatException {
      // GF-02166 — Convert malformed server challenges to a domain error.
      throw const ChallengeException(
        'サーバーから返されたチャレンジをBase64urlとして解釈できませんでした。',
        code: 'invalid_challenge',
      );
    }
  }
}

/// GF-01092 — Creates an instance for new device usecase.
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
