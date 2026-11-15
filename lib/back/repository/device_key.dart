import 'dart:convert';

import 'package:flutter/services.dart';

import '../share/base64_url.dart';
import '../../entity/model/device_key.dart';
import '../../entity/model/platform.dart';
import '../../entity/model/registered_device_key.dart';
import 'secure_store.dart';

/// OS-specific hardware-backed key operations.
///
/// Implementations must:
/// - create the key inside the OS key store (never in Dart memory),
/// - bind the attestation challenge into the key generation request,
/// - sign the raw decoded challenge bytes,
/// - return signatures as unpadded Base64url.
abstract interface class DeviceKeyRepository {
  /// GF-00453 — Computes DeviceKeyRepository.platform.
  String get platform;

  /// GF-00454 — Handles availability in DeviceKeyRepository.
  Future<DeviceKeyAvailability> availability();

  /// GF-00455 — Handles generate key in DeviceKeyRepository.
  Future<GeneratedDeviceKey> generateKey({
    required String keyIdentifier,
    required Uint8List attestationChallenge,
  });

  /// GF-00456 — Handles sign in DeviceKeyRepository.
  Future<String> sign({required String keyIdentifier, required Uint8List data});

  /// GF-00457 — Checks whether has key.
  Future<bool> hasKey(String keyIdentifier);

  /// GF-00458 — Handles delete key in DeviceKeyRepository.
  Future<void> deleteKey(String keyIdentifier);
}

final class AndroidDeviceKeyRepository implements DeviceKeyRepository {
  /// GF-00459 — Initializes AndroidDeviceKeyRepository.
  AndroidDeviceKeyRepository({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.gorapeflutter.gf_app/device_key';
  final MethodChannel _channel;

  /// GF-00460 — Computes AndroidDeviceKeyRepository.platform.
  @override
  String get platform => 'android';

  /// GF-00461 — Handles availability in AndroidDeviceKeyRepository.
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

  /// GF-00462 — Handles generate key in AndroidDeviceKeyRepository.
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

  /// GF-00463 — Handles sign in AndroidDeviceKeyRepository.
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

  /// GF-00464 — Checks whether has key.
  @override
  Future<bool> hasKey(String keyIdentifier) async =>
      await _channel.invokeMethod<bool>('hasKey', {
        'keyIdentifier': keyIdentifier,
      }) ??
      false;

  /// GF-00465 — Handles delete key in AndroidDeviceKeyRepository.
  @override
  Future<void> deleteKey(String keyIdentifier) => _channel.invokeMethod<void>(
    'deleteKey',
    {'keyIdentifier': keyIdentifier},
  );
}

/// Native Secure Enclave / CNG-TPM / TPM2 key store bridge. These providers
/// report local key protection separately from remotely verifiable attestation.
final class PlatformDeviceKeyRepository implements DeviceKeyRepository {
  /// GF-01178 — Initializes a platform-specific native key repository.
  PlatformDeviceKeyRepository({
    required this.platform,
    required this.channelName,
    MethodChannel? channel,
  }) : _channel = channel ?? MethodChannel(channelName);

  @override
  final String platform;
  final String channelName;
  final MethodChannel _channel;

  /// GF-01179 — Reads local key capability without claiming remote attestation.
  @override
  Future<DeviceKeyAvailability> availability() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'availability',
      );
      if (result == null) {
        return DeviceKeyAvailability.unsupported(
          '$platform native key provider returned no capability result.',
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
      return DeviceKeyAvailability.unsupported(
        '$platform native hardware key provider is not installed.',
      );
    } on PlatformException catch (error) {
      return DeviceKeyAvailability.unsupported(
        error.message ?? '$platform native key provider is unavailable.',
      );
    }
  }

  /// GF-01180 — Creates a native P-256 key and retains its assurance boundary.
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
        message: '$platform native key store returned no key.',
      );
    }
    final publicKeyPem = result['publicKeyPem'];
    if (publicKeyPem is! String ||
        !publicKeyPem.startsWith('-----BEGIN PUBLIC KEY-----')) {
      throw PlatformException(
        code: 'missing_public_key',
        message: '$platform native key store returned no public key.',
      );
    }
    final rawEvidence = result['attestationEvidence'];
    if (rawEvidence is! Map) {
      throw PlatformException(
        code: 'missing_assurance_boundary',
        message:
            '$platform provider did not describe its attestation boundary.',
      );
    }
    final evidence = <String, dynamic>{};
    for (final entry in rawEvidence.entries) {
      if (entry.key is! String) {
        throw PlatformException(
          code: 'malformed_attestation_evidence',
          message: '$platform attestation metadata is malformed.',
        );
      }
      evidence[entry.key as String] = entry.value;
    }
    final chain =
        (result['certificateChain'] as List<dynamic>?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];
    if (chain.isNotEmpty) evidence['certificate_chain'] = chain;
    return GeneratedDeviceKey(
      keyIdentifier: result['keyIdentifier'] as String? ?? keyIdentifier,
      publicKeyPem: publicKeyPem,
      algorithm: result['algorithm'] as String? ?? 'ES256',
      securityLevel: result['securityLevel'] as String?,
      evidence: evidence,
    );
  }

  /// GF-01181 — Signs challenge bytes with the native non-exportable key.
  @override
  Future<String> sign({
    required String keyIdentifier,
    required Uint8List data,
  }) async {
    final result = await _channel.invokeMethod<String>('sign', {
      'keyIdentifier': keyIdentifier,
      'data': Base64Url.encode(data),
    });
    if (result == null || result.isEmpty) {
      throw PlatformException(
        code: 'signature_failed',
        message: '$platform native key store returned no signature.',
      );
    }
    return result;
  }

  /// GF-01182 — Checks for the key in the platform-specific namespace.
  @override
  Future<bool> hasKey(String keyIdentifier) async =>
      await _channel.invokeMethod<bool>('hasKey', {
        'keyIdentifier': keyIdentifier,
      }) ??
      false;

  /// GF-01183 — Deletes only the named native device key.
  @override
  Future<void> deleteKey(String keyIdentifier) => _channel.invokeMethod<void>(
    'deleteKey',
    {'keyIdentifier': keyIdentifier},
  );
}

final class UnsupportedDeviceKeyRepository implements DeviceKeyRepository {
  /// GF-00466 — Initializes UnsupportedDeviceKeyRepository.
  const UnsupportedDeviceKeyRepository({
    required this.platform,
    required this.reason,
  });

  @override
  final String platform;
  final String reason;

  /// GF-00467 — Handles availability in UnsupportedDeviceKeyRepository.
  @override
  Future<DeviceKeyAvailability> availability() async =>
      DeviceKeyAvailability.unsupported(reason);

  /// GF-00468 — Handles generate key in UnsupportedDeviceKeyRepository.
  @override
  Future<GeneratedDeviceKey> generateKey({
    required String keyIdentifier,
    required Uint8List attestationChallenge,
  }) => throw UnsupportedError(reason);

  /// GF-00469 — Handles sign in UnsupportedDeviceKeyRepository.
  @override
  Future<String> sign({
    required String keyIdentifier,
    required Uint8List data,
  }) => throw UnsupportedError(reason);

  /// GF-00470 — Checks whether has key.
  @override
  Future<bool> hasKey(String keyIdentifier) async => false;

  /// GF-00471 — Handles delete key in UnsupportedDeviceKeyRepository.
  @override
  Future<void> deleteKey(String keyIdentifier) async {}
}

/// GF-00472 — Creates an instance for new device key repository.
DeviceKeyRepository newDeviceKeyRepository(RuntimePlatform platform) =>
    switch (platform) {
      RuntimePlatform.android => AndroidDeviceKeyRepository(),
      RuntimePlatform.windows => PlatformDeviceKeyRepository(
        platform: 'windows',
        channelName: 'com.gorapeflutter.gf_app/device_key',
      ),
      RuntimePlatform.ios => PlatformDeviceKeyRepository(
        platform: 'ios',
        channelName: 'com.gorapeflutter.gf_app/device_key',
      ),
      RuntimePlatform.macos => PlatformDeviceKeyRepository(
        platform: 'macos',
        channelName: 'com.gorapeflutter.gf_app/device_key',
      ),
      RuntimePlatform.linux => PlatformDeviceKeyRepository(
        platform: 'linux',
        channelName: 'com.gorapeflutter.gf_app/device_key',
      ),
      RuntimePlatform.web => const UnsupportedDeviceKeyRepository(
        platform: 'web',
        reason:
            'Browsers do not expose the OS attestation key store used here.',
      ),
      RuntimePlatform.unknown => const UnsupportedDeviceKeyRepository(
        platform: 'unknown',
        reason: 'Unknown platform.',
      ),
    };

abstract interface class DeviceKeyStoreRepository {
  /// GF-00473 — Handles load in DeviceKeyStoreRepository.
  Future<RegisteredDeviceKey?> load(String projectId, String deviceId);

  /// GF-00474 — Handles for project in DeviceKeyStoreRepository.
  Future<List<RegisteredDeviceKey>> forProject(String projectId);

  /// GF-00475 — Handles save in DeviceKeyStoreRepository.
  Future<void> save(RegisteredDeviceKey record);

  /// GF-00476 — Handles delete in DeviceKeyStoreRepository.
  Future<void> delete(String projectId, String deviceId);
}

final class DeviceKeyStoreRepositoryImpl implements DeviceKeyStoreRepository {
  /// GF-00477 — Initializes DeviceKeyStoreRepositoryImpl.
  DeviceKeyStoreRepositoryImpl(this._store);
  final SecureStore _store;

  /// GF-00478 — Handles record key in DeviceKeyStoreRepositoryImpl.
  static String _recordKey(String projectId, String deviceId) =>
      'gorape.device_key.$projectId.$deviceId';

  /// GF-00479 — Handles index key in DeviceKeyStoreRepositoryImpl.
  static String _indexKey(String projectId) =>
      'gorape.device_key_index.$projectId';

  /// GF-00480 — Handles load in DeviceKeyStoreRepositoryImpl.
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

  /// GF-00481 — Handles for project in DeviceKeyStoreRepositoryImpl.
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
    records.sort(
      /* GF-00482 — Runs an inline callback in DeviceKeyStoreRepositoryImpl.forProject. */ (
        a,
        b,
      ) => b.createdAt.compareTo(a.createdAt),
    );
    return records;
  }

  /// GF-00483 — Handles save in DeviceKeyStoreRepositoryImpl.
  @override
  Future<void> save(RegisteredDeviceKey record) async {
    await _store.write(
      _recordKey(record.projectId, record.deviceId),
      record.encode(),
    );
    final ids = (await forProject(record.projectId))
        .map(
          /* GF-00484 — Runs an inline callback in DeviceKeyStoreRepositoryImpl.save. */ (
            item,
          ) => item.deviceId,
        )
        .toSet()
        .toList();
    if (!ids.contains(record.deviceId)) ids.insert(0, record.deviceId);
    await _store.write(_indexKey(record.projectId), jsonEncode(ids));
  }

  /// GF-00485 — Handles delete in DeviceKeyStoreRepositoryImpl.
  @override
  Future<void> delete(String projectId, String deviceId) async {
    await _store.delete(_recordKey(projectId, deviceId));
    final ids = (await forProject(projectId))
        .map(
          /* GF-00486 — Runs an inline callback in DeviceKeyStoreRepositoryImpl.delete. */ (
            item,
          ) => item.deviceId,
        )
        .where(
          /* GF-00487 — Runs an inline callback in DeviceKeyStoreRepositoryImpl.delete. */ (
            id,
          ) => id != deviceId,
        )
        .toList(growable: false);
    await _store.write(_indexKey(projectId), jsonEncode(ids));
  }
}

/// GF-00488 — Creates an instance for new device key store repository.
DeviceKeyStoreRepository newDeviceKeyStoreRepository(SecureStore store) =>
    DeviceKeyStoreRepositoryImpl(store);
