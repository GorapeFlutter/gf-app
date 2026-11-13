import 'package:flutter/services.dart';

import '../api/gorape_api_client.dart';
import '../api/models/attestation.dart';
import '../api/models/device.dart';
import '../api/models/registration.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/base64_url.dart';
import '../core/utils/random_id.dart';
import 'device_key_provider.dart';
import 'device_key_store.dart';

class RegistrationResult {
  const RegistrationResult({
    required this.device,
    required this.key,
    required this.securityLevel,
  });

  final Device device;
  final RegisteredDeviceKey key;
  final String? securityLevel;
}

/// Orchestrates Gorape's two-step device registration.
///
/// 1. Read local provider support and backend verifier capabilities.
/// 2. Request a single-use registration challenge.
/// 3. Generate an OS-protected key with the raw challenge bound into the
///    attestation request.
/// 4. Submit the public key and platform evidence.
class DeviceRegistrationService {
  const DeviceRegistrationService({
    required GorapeApi api,
    required DeviceKeyProvider keyProvider,
    required DeviceKeyStore keyStore,
  }) : _api = api,
       _keyProvider = keyProvider,
       _keyStore = keyStore;

  final GorapeApi _api;
  final DeviceKeyProvider _keyProvider;
  final DeviceKeyStore _keyStore;

  Future<RegistrationResult> register({
    required String projectId,
    required String displayName,
    String? platform,
  }) async {
    final effectivePlatform = platform ?? _keyProvider.platform;
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      throw const ConfigurationException(
        'デバイス名を入力してください。',
        code: 'display_name_required',
      );
    }

    final availability = await _keyProvider.availability();
    if (!availability.supported) {
      throw DeviceKeyUnsupportedException(
        availability.reason ?? 'このOSではOS保護鍵を生成できません。',
        platform: effectivePlatform,
        guidance: 'Android実機で実行してください。',
      );
    }

    final capabilities = await _api.attestationCapabilities(projectId);
    _ensureBackendSupports(capabilities, effectivePlatform);

    final challenge = await _api.createRegistrationChallenge(
      projectId,
      platform: effectivePlatform,
    );
    if (challenge.isExpired) {
      throw const ChallengeException(
        '登録チャレンジの有効期限が切れています。もう一度お試しください。',
        code: 'challenge_expired',
      );
    }

    final challengeBytes = _decodeChallenge(challenge.challenge);
    final keyIdentifier = 'gorape-$effectivePlatform-${randomId(12)}';
    GeneratedDeviceKey generated;
    try {
      generated = await _keyProvider.generateKey(
        keyIdentifier: keyIdentifier,
        attestationChallenge: challengeBytes,
      );
    } on PlatformException catch (error) {
      throw DeviceKeyUnsupportedException(
        error.message ?? 'OS保護鍵を生成できませんでした。',
        platform: effectivePlatform,
        guidance: '端末の画面ロック設定とKeystoreの状態を確認してください。',
      );
    }

    try {
      final device = await _api.verifyRegistration(
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
      // Never leave an orphaned key that is not associated with a device.
      try {
        await _keyProvider.deleteKey(generated.keyIdentifier);
      } on Object {
        // Best effort cleanup.
      }
      rethrow;
    }
  }

  Future<void> deleteLocalKey(String projectId, String deviceId) async {
    final record = await _keyStore.load(projectId, deviceId);
    if (record == null) return;
    try {
      await _keyProvider.deleteKey(record.keyIdentifier);
    } on Object {
      // The backend revocation already succeeded; local cleanup is best effort.
    }
    await _keyStore.delete(projectId, deviceId);
  }

  void _ensureBackendSupports(
    AttestationCapabilities capabilities,
    String platform,
  ) {
    final status = capabilities.statusFor(platform);
    if (status == 'implemented') return;
    if (status == 'unconfigured') {
      throw AttestationNotConfiguredException(
        'GorapeのAndroid Attestation検証が未設定です。',
        code: 'attestation_unconfigured',
        guidance:
            'Gorapeの Application.Server.Attestation.android_trust_anchors に'
            'GoogleのKey Attestation Root CAを設定してください。'
            'gf-appでは ./scripts/generate-android-trust-config.sh の後に '
            './scripts/gorape-up.sh --android-attestation を実行すると設定できます。'
            '設定後に `GET /v1/projects/{projectId}/attestation/capabilities` '
            'が "implemented" を返せば登録できます。',
      );
    }
    throw BackendAttestationUnsupportedException(
      'Gorapeバックエンドは $platform のAttestationを未対応として扱っています。',
      platform: platform,
      code: 'attestation_unsupported',
      guidance:
          '現行バックエンドではAndroid Key Attestationのみ実装されています。'
          'Windows TPM、iOS、macOSはバックエンド側の対応が必要です。',
    );
  }

  Uint8List _decodeChallenge(String challenge) {
    try {
      final decoded = Base64Url.decode(challenge);
      if (decoded.isEmpty) {
        throw const FormatException('empty challenge');
      }
      return decoded;
    } on FormatException {
      throw const ChallengeException(
        'サーバーから返されたチャレンジをBase64urlとして解釈できませんでした。',
        code: 'invalid_challenge',
      );
    }
  }
}
