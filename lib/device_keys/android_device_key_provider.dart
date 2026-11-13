import 'package:flutter/services.dart';

import '../core/utils/base64_url.dart';
import 'device_key_provider.dart';

/// Android Keystore + Key Attestation adapter.
///
/// The Kotlin side creates an EC P-256 key with
/// `KeyGenParameterSpec.setAttestationChallenge(challenge)`. The certificate
/// chain is returned leaf-first, matching Gorape's client integration contract.
class AndroidDeviceKeyProvider implements DeviceKeyProvider {
  AndroidDeviceKeyProvider({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'com.gorapeflutter.gf_app/device_key';
  static const String platformName = 'android';

  final MethodChannel _channel;

  @override
  String get platform => platformName;

  @override
  Future<DeviceKeyAvailability> availability() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'availability',
      );
      if (result == null) {
        return const DeviceKeyAvailability.unsupported(
          'Android Keystoreの状態を取得できませんでした。',
        );
      }
      final supported = result['supported'] == true;
      return DeviceKeyAvailability(
        supported: supported,
        hardwareBacked: result['hardwareBacked'] == true,
        attestationSupported: result['attestationSupported'] == true,
        securityLevel: result['securityLevel'] as String?,
        reason: result['reason'] as String?,
      );
    } on MissingPluginException {
      return const DeviceKeyAvailability.unsupported(
        'Android Keystoreプラグインが読み込まれていません。',
      );
    } on PlatformException catch (error) {
      return DeviceKeyAvailability.unsupported(
        error.message ?? 'Android Keystoreを初期化できませんでした。',
      );
    }
  }

  @override
  Future<GeneratedDeviceKey> generateKey({
    required String keyIdentifier,
    required Uint8List attestationChallenge,
  }) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'generateKey',
      {
        'keyIdentifier': keyIdentifier,
        // The native side decodes this to raw bytes and passes them to
        // KeyGenParameterSpec.setAttestationChallenge.
        'challenge': Base64Url.encode(attestationChallenge),
      },
    );
    if (result == null) {
      throw PlatformException(
        code: 'key_generation_failed',
        message: 'Android Keystoreが鍵を生成しませんでした。',
      );
    }
    final publicKeyPem = result['publicKeyPem'] as String?;
    final certificateChain =
        (result['certificateChain'] as List<dynamic>?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];
    if (publicKeyPem == null || publicKeyPem.isEmpty) {
      throw PlatformException(
        code: 'missing_public_key',
        message: 'Android Keystoreから公開鍵が返されませんでした。',
      );
    }
    if (certificateChain.isEmpty) {
      throw PlatformException(
        code: 'missing_certificate_chain',
        message: 'Android Key Attestation証明書チェーンが返されませんでした。',
      );
    }
    return GeneratedDeviceKey(
      keyIdentifier: result['keyIdentifier'] as String? ?? keyIdentifier,
      publicKeyPem: publicKeyPem,
      algorithm: result['algorithm'] as String? ?? 'ES256',
      securityLevel: result['securityLevel'] as String?,
      evidence: {'certificate_chain': certificateChain},
    );
  }

  @override
  Future<String> sign({
    required String keyIdentifier,
    required Uint8List data,
  }) async {
    final signature = await _channel.invokeMethod<String>('sign', {
      'keyIdentifier': keyIdentifier,
      'data': Base64Url.encode(data),
    });
    if (signature == null || signature.isEmpty) {
      throw PlatformException(
        code: 'signature_failed',
        message: 'Android Keystoreが署名を返しませんでした。',
      );
    }
    return signature;
  }

  @override
  Future<bool> hasKey(String keyIdentifier) async {
    final result = await _channel.invokeMethod<bool>('hasKey', {
      'keyIdentifier': keyIdentifier,
    });
    return result ?? false;
  }

  @override
  Future<void> deleteKey(String keyIdentifier) async {
    await _channel.invokeMethod<void>('deleteKey', {
      'keyIdentifier': keyIdentifier,
    });
  }
}
