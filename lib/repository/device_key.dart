import 'dart:convert';

import 'package:flutter/services.dart';

import '../share/base64_url.dart';
import '../entity/model/device_key.dart';
import '../entity/model/platform.dart';
import '../entity/model/registered_device_key.dart';
import 'secure_store.dart';

/// OS-specific hardware-backed key operations.
///
/// Implementations must:
/// - create the key inside the OS key store (never in Dart memory),
/// - bind the attestation challenge into the key generation request,
/// - sign the raw decoded challenge bytes,
/// - return signatures as unpadded Base64url.
abstract interface class DeviceKeyRepository {
  String get platform;

  Future<DeviceKeyAvailability> availability();

  Future<GeneratedDeviceKey> generateKey({
    required String keyIdentifier,
    required Uint8List attestationChallenge,
  });

  Future<String> sign({required String keyIdentifier, required Uint8List data});

  Future<bool> hasKey(String keyIdentifier);

  Future<void> deleteKey(String keyIdentifier);
}

final class AndroidDeviceKeyRepository implements DeviceKeyRepository {
  AndroidDeviceKeyRepository({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.gorapeflutter.gf_app/device_key';
  final MethodChannel _channel;

  @override
  String get platform => 'android';

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
      return DeviceKeyAvailability(
        supported: result['supported'] == true,
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
    final result = await _channel
        .invokeMapMethod<String, dynamic>('generateKey', {
          'keyIdentifier': keyIdentifier,
          'challenge': Base64Url.encode(attestationChallenge),
        });
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
  Future<bool> hasKey(String keyIdentifier) async =>
      await _channel.invokeMethod<bool>('hasKey', {
        'keyIdentifier': keyIdentifier,
      }) ??
      false;

  @override
  Future<void> deleteKey(String keyIdentifier) => _channel.invokeMethod<void>(
    'deleteKey',
    {'keyIdentifier': keyIdentifier},
  );
}

final class UnsupportedDeviceKeyRepository implements DeviceKeyRepository {
  const UnsupportedDeviceKeyRepository({
    required this.platform,
    required this.reason,
  });

  @override
  final String platform;
  final String reason;

  @override
  Future<DeviceKeyAvailability> availability() async =>
      DeviceKeyAvailability.unsupported(reason);
  @override
  Future<GeneratedDeviceKey> generateKey({
    required String keyIdentifier,
    required Uint8List attestationChallenge,
  }) => throw UnsupportedError(reason);
  @override
  Future<String> sign({
    required String keyIdentifier,
    required Uint8List data,
  }) => throw UnsupportedError(reason);
  @override
  Future<bool> hasKey(String keyIdentifier) async => false;
  @override
  Future<void> deleteKey(String keyIdentifier) async {}
}

DeviceKeyRepository newDeviceKeyRepository(
  RuntimePlatform platform,
) => switch (platform) {
  RuntimePlatform.android => AndroidDeviceKeyRepository(),
  RuntimePlatform.windows => const UnsupportedDeviceKeyRepository(
    platform: 'windows',
    reason:
        'Windows TPM attestation is reported as unsupported by the current Gorape backend.',
  ),
  RuntimePlatform.ios => const UnsupportedDeviceKeyRepository(
    platform: 'ios',
    reason:
        'iOS attestation is reported as unsupported by the current Gorape backend.',
  ),
  RuntimePlatform.macos => const UnsupportedDeviceKeyRepository(
    platform: 'macos',
    reason:
        'macOS attestation is reported as unsupported by the current Gorape backend.',
  ),
  RuntimePlatform.linux => const UnsupportedDeviceKeyRepository(
    platform: 'linux',
    reason: 'Gorape does not define a Linux attestation platform.',
  ),
  RuntimePlatform.web => const UnsupportedDeviceKeyRepository(
    platform: 'web',
    reason: 'Browsers do not expose the OS attestation key store used here.',
  ),
  RuntimePlatform.unknown => const UnsupportedDeviceKeyRepository(
    platform: 'unknown',
    reason: 'Unknown platform.',
  ),
};

abstract interface class DeviceKeyStoreRepository {
  Future<RegisteredDeviceKey?> load(String projectId, String deviceId);
  Future<List<RegisteredDeviceKey>> forProject(String projectId);
  Future<void> save(RegisteredDeviceKey record);
  Future<void> delete(String projectId, String deviceId);
}

final class DeviceKeyStoreRepositoryImpl implements DeviceKeyStoreRepository {
  DeviceKeyStoreRepositoryImpl(this._store);
  final SecureStore _store;

  static String _recordKey(String projectId, String deviceId) =>
      'gorape.device_key.$projectId.$deviceId';
  static String _indexKey(String projectId) =>
      'gorape.device_key_index.$projectId';

  @override
  Future<RegisteredDeviceKey?> load(String projectId, String deviceId) async {
    final raw = await _store.read(_recordKey(projectId, deviceId));
    if (raw == null) return null;
    try {
      return RegisteredDeviceKey.decode(raw);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<List<RegisteredDeviceKey>> forProject(String projectId) async {
    final raw = await _store.read(_indexKey(projectId));
    if (raw == null) return const [];
    List<dynamic> ids;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      ids = decoded;
    } on FormatException {
      return const [];
    }
    final records = <RegisteredDeviceKey>[];
    for (final id in ids.whereType<String>()) {
      final record = await load(projectId, id);
      if (record != null) records.add(record);
    }
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  @override
  Future<void> save(RegisteredDeviceKey record) async {
    await _store.write(
      _recordKey(record.projectId, record.deviceId),
      record.encode(),
    );
    final ids = (await forProject(
      record.projectId,
    )).map((item) => item.deviceId).toSet().toList();
    if (!ids.contains(record.deviceId)) ids.insert(0, record.deviceId);
    await _store.write(_indexKey(record.projectId), jsonEncode(ids));
  }

  @override
  Future<void> delete(String projectId, String deviceId) async {
    await _store.delete(_recordKey(projectId, deviceId));
    final ids = (await forProject(projectId))
        .map((item) => item.deviceId)
        .where((id) => id != deviceId)
        .toList(growable: false);
    await _store.write(_indexKey(projectId), jsonEncode(ids));
  }
}

DeviceKeyStoreRepository newDeviceKeyStoreRepository(SecureStore store) =>
    DeviceKeyStoreRepositoryImpl(store);
