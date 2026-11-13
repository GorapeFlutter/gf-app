import 'package:flutter/services.dart';

import '../api/gorape_api_client.dart';
import '../api/models/registration.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/base64_url.dart';
import 'device_key_provider.dart';
import 'device_key_store.dart';

/// Proves possession of the registered device key.
///
/// Gorape issues a new challenge for each proof. The raw decoded challenge
/// bytes are signed by the OS key; the Base64url signature is sent back.
class DeviceProofService {
  const DeviceProofService({
    required GorapeApi api,
    required DeviceKeyProvider keyProvider,
    required DeviceKeyStore keyStore,
  }) : _api = api,
       _keyProvider = keyProvider,
       _keyStore = keyStore;

  final GorapeApi _api;
  final DeviceKeyProvider _keyProvider;
  final DeviceKeyStore _keyStore;

  Future<RegisteredDeviceKey> verifyPossession({
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

    final available = await _keyProvider.hasKey(record.keyIdentifier);
    if (!available) {
      throw const DeviceKeyUnavailableException(
        'OSキーストアに秘密鍵が見つかりません。',
        guidance: '端末のロック解除状態を確認するか、デバイスを再登録してください。',
      );
    }

    final challenge = await _api.createProofChallenge(projectId, deviceId);
    if (challenge.isExpired) {
      throw const ChallengeException(
        '署名チャレンジの有効期限が切れています。もう一度お試しください。',
        code: 'challenge_expired',
      );
    }

    final challengeBytes = _decodeChallenge(challenge.challenge);
    String signature;
    try {
      signature = await _keyProvider.sign(
        keyIdentifier: record.keyIdentifier,
        data: challengeBytes,
      );
    } on PlatformException catch (error) {
      throw DeviceKeyUnavailableException(
        error.message ?? 'OS保護鍵で署名できませんでした。',
        guidance: 'Keystoreの鍵が無効化された可能性があります。再登録してください。',
      );
    }

    await _api.verifyProof(
      projectId,
      deviceId,
      ProofVerifyRequest(
        challengeId: challenge.challengeId,
        signature: signature,
      ),
    );
    return record;
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
