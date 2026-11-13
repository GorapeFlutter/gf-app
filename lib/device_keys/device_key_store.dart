import 'dart:convert';

import '../core/storage/secure_store.dart';

/// Locally persisted metadata for a registered device key.
///
/// Only the Keystore alias is stored. Private key bytes never leave Android
/// Keystore / Secure Enclave.
class RegisteredDeviceKey {
  const RegisteredDeviceKey({
    required this.projectId,
    required this.deviceId,
    required this.keyIdentifier,
    required this.algorithm,
    required this.platform,
    required this.displayName,
    required this.createdAt,
    this.securityLevel,
  });

  final String projectId;
  final String deviceId;
  final String keyIdentifier;
  final String algorithm;
  final String platform;
  final String displayName;
  final DateTime createdAt;
  final String? securityLevel;

  Map<String, dynamic> toJson() => {
    'project_id': projectId,
    'device_id': deviceId,
    'key_identifier': keyIdentifier,
    'algorithm': algorithm,
    'platform': platform,
    'display_name': displayName,
    'created_at': createdAt.toUtc().toIso8601String(),
    'security_level': securityLevel,
  };

  factory RegisteredDeviceKey.fromJson(Map<String, dynamic> json) {
    return RegisteredDeviceKey(
      projectId: json['project_id'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      keyIdentifier: json['key_identifier'] as String? ?? '',
      algorithm: json['algorithm'] as String? ?? 'ES256',
      platform: json['platform'] as String? ?? 'android',
      displayName: json['display_name'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      securityLevel: json['security_level'] as String?,
    );
  }

  static RegisteredDeviceKey decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid device key record');
    }
    return RegisteredDeviceKey.fromJson(decoded);
  }

  String encode() => jsonEncode(toJson());
}

class DeviceKeyStore {
  DeviceKeyStore(this._store);

  final SecureStore _store;

  static String _recordKey(String projectId, String deviceId) =>
      'gorape.device_key.$projectId.$deviceId';

  static String _indexKey(String projectId) =>
      'gorape.device_key_index.$projectId';

  Future<RegisteredDeviceKey?> load(String projectId, String deviceId) async {
    final raw = await _store.read(_recordKey(projectId, deviceId));
    if (raw == null) return null;
    try {
      return RegisteredDeviceKey.decode(raw);
    } on FormatException {
      return null;
    }
  }

  Future<List<RegisteredDeviceKey>> forProject(String projectId) async {
    final raw = await _store.read(_indexKey(projectId));
    if (raw == null) return const [];
    final List<dynamic> ids;
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

  Future<void> save(RegisteredDeviceKey record) async {
    await _store.write(
      _recordKey(record.projectId, record.deviceId),
      record.encode(),
    );
    final index = await forProject(record.projectId);
    final ids = index.map((item) => item.deviceId).toSet().toList();
    if (!ids.contains(record.deviceId)) {
      ids.insert(0, record.deviceId);
    }
    await _store.write(_indexKey(record.projectId), jsonEncode(ids));
  }

  Future<void> delete(String projectId, String deviceId) async {
    await _store.delete(_recordKey(projectId, deviceId));
    final index = await forProject(projectId);
    final ids = index
        .map((item) => item.deviceId)
        .where((id) => id != deviceId)
        .toList(growable: false);
    await _store.write(_indexKey(projectId), jsonEncode(ids));
  }
}
