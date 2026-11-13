import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../entity/model/attestation.dart';
import '../entity/model/device.dart';
import '../entity/model/group.dart';
import '../entity/model/project.dart';
import '../entity/model/role_binding.dart';
import '../entity/request/device.dart';
import '../entity/request/group.dart';
import '../entity/response/challenge.dart';
import '../entity/response/common.dart';
import '../entity/response/attestation.dart';
import '../share/error.dart';

/// Gorape API surface used by the Flutter client.
///
/// Only endpoints present in `docs/swagger/swagger.yaml` are implemented.
/// Policy or passkey endpoints are intentionally absent because the current
/// backend contract does not define them.
abstract interface class GorapeApi {
  Future<Map<String, dynamic>> health();

  Future<List<Project>> listProjects();

  Future<Project> getProject(String projectId);

  Future<List<Device>> listDevices(String projectId);

  Future<Device> getDevice(String projectId, String deviceId);

  Future<void> revokeDevice(String projectId, String deviceId);

  Future<List<Group>> listGroups(String projectId);

  Future<Group> getGroup(String projectId, String groupId);

  Future<Group> createGroup(String projectId, GroupCreateRequest request);

  Future<Group> updateGroup(
    String projectId,
    String groupId,
    GroupUpdateRequest request,
  );

  Future<void> deleteGroup(String projectId, String groupId);

  Future<List<Device>> listGroupDevices(String projectId, String groupId);

  Future<void> bindDeviceToGroup(
    String projectId,
    String groupId,
    String deviceId,
  );

  Future<void> unbindDeviceFromGroup(
    String projectId,
    String groupId,
    String deviceId,
  );

  Future<List<ProjectRoleBinding>> listProjectRoles(String projectId);

  Future<void> putProjectRole(String projectId, RoleCreateRequest request);

  Future<void> deleteProjectRole(String projectId, String bindingId);

  Future<List<GroupRoleBinding>> listGroupRoles(
    String projectId,
    String groupId,
  );

  Future<void> putGroupRole(
    String projectId,
    String groupId,
    RoleCreateRequest request,
  );

  Future<void> deleteGroupRole(
    String projectId,
    String groupId,
    String bindingId,
  );

  Future<Challenge> createRegistrationChallenge(
    String projectId, {
    required String platform,
  });

  Future<Device> verifyRegistration(
    String projectId,
    RegistrationVerifyRequest request,
  );

  Future<Challenge> createProofChallenge(String projectId, String deviceId);

  Future<void> verifyProof(
    String projectId,
    String deviceId,
    ProofVerifyRequest request,
  );

  Future<AttestationCapabilities> attestationCapabilities(String projectId);

  Future<List<AttestationRecord>> attestations(
    String projectId,
    String deviceId,
  );
}

GorapeApi newGorapeApi({
  required String baseUrl,
  required http.Client httpClient,
  required String? Function() accessTokenProvider,
  Future<bool> Function()? refreshAccessToken,
  Duration timeout = const Duration(seconds: 15),
}) => GorapeApiClient(
  baseUrl: baseUrl,
  httpClient: httpClient,
  accessTokenProvider: accessTokenProvider,
  refreshAccessToken: refreshAccessToken,
  timeout: timeout,
);

/// HTTP implementation of [GorapeApi].
///
/// [accessTokenProvider] must return the OIDC **access token**. The ID token is
/// never sent to Gorape; the backend rejects ID tokens as API credentials.
class GorapeApiClient implements GorapeApi {
  GorapeApiClient({
    required String baseUrl,
    required http.Client httpClient,
    required String? Function() accessTokenProvider,
    Future<bool> Function()? refreshAccessToken,
    this.timeout = const Duration(seconds: 15),
  }) : _baseUrl = _normalizeBaseUrl(baseUrl),
       _http = httpClient,
       _accessTokenProvider = accessTokenProvider,
       _refreshAccessToken = refreshAccessToken;

  final String _baseUrl;
  final http.Client _http;
  final String? Function() _accessTokenProvider;
  final Future<bool> Function()? _refreshAccessToken;
  final Duration timeout;

  static String _normalizeBaseUrl(String value) {
    var base = value.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return base;
  }

  @override
  Future<Map<String, dynamic>> health() async {
    final body = await _request('GET', '/health', authenticated: false);
    return body is Map<String, dynamic> ? body : const {};
  }

  @override
  Future<List<Project>> listProjects() async {
    final body = await _request('GET', '/v1/projects');
    return _asList(
      body,
    ).map((item) => Project.fromJson(_asMap(item))).toList(growable: false);
  }

  @override
  Future<Project> getProject(String projectId) async {
    final body = await _request('GET', '/v1/projects/${_segment(projectId)}');
    return Project.fromJson(_asMap(body));
  }

  @override
  Future<List<Device>> listDevices(String projectId) async {
    final body = await _request(
      'GET',
      '/v1/projects/${_segment(projectId)}/devices',
    );
    return _asList(
      body,
    ).map((item) => Device.fromJson(_asMap(item))).toList(growable: false);
  }

  @override
  Future<Device> getDevice(String projectId, String deviceId) async {
    final body = await _request(
      'GET',
      '/v1/projects/${_segment(projectId)}/devices/${_segment(deviceId)}',
    );
    return Device.fromJson(_asMap(body));
  }

  @override
  Future<void> revokeDevice(String projectId, String deviceId) async {
    await _request(
      'DELETE',
      '/v1/projects/${_segment(projectId)}/devices/${_segment(deviceId)}',
    );
  }

  @override
  Future<List<Group>> listGroups(String projectId) async {
    final body = await _request(
      'GET',
      '/v1/projects/${_segment(projectId)}/groups',
    );
    return _asList(
      body,
    ).map((item) => Group.fromJson(_asMap(item))).toList(growable: false);
  }

  @override
  Future<Group> getGroup(String projectId, String groupId) async {
    final body = await _request(
      'GET',
      '/v1/projects/${_segment(projectId)}/groups/${_segment(groupId)}',
    );
    return Group.fromJson(_asMap(body));
  }

  @override
  Future<Group> createGroup(
    String projectId,
    GroupCreateRequest request,
  ) async {
    final body = await _request(
      'POST',
      '/v1/projects/${_segment(projectId)}/groups',
      body: request.toJson(),
    );
    return Group.fromJson(_asMap(body));
  }

  @override
  Future<Group> updateGroup(
    String projectId,
    String groupId,
    GroupUpdateRequest request,
  ) async {
    final body = await _request(
      'PATCH',
      '/v1/projects/${_segment(projectId)}/groups/${_segment(groupId)}',
      body: request.toJson(),
    );
    return Group.fromJson(_asMap(body));
  }

  @override
  Future<void> deleteGroup(String projectId, String groupId) async {
    await _request(
      'DELETE',
      '/v1/projects/${_segment(projectId)}/groups/${_segment(groupId)}',
    );
  }

  @override
  Future<List<Device>> listGroupDevices(
    String projectId,
    String groupId,
  ) async {
    final body = await _request(
      'GET',
      '/v1/projects/${_segment(projectId)}/groups/${_segment(groupId)}/devices',
    );
    return _asList(
      body,
    ).map((item) => Device.fromJson(_asMap(item))).toList(growable: false);
  }

  @override
  Future<void> bindDeviceToGroup(
    String projectId,
    String groupId,
    String deviceId,
  ) async {
    await _request(
      'POST',
      '/v1/projects/${_segment(projectId)}/groups/${_segment(groupId)}/devices',
      body: DeviceGroupCreateRequest(deviceId: deviceId).toJson(),
    );
  }

  @override
  Future<void> unbindDeviceFromGroup(
    String projectId,
    String groupId,
    String deviceId,
  ) async {
    await _request(
      'DELETE',
      '/v1/projects/${_segment(projectId)}/groups/'
          '${_segment(groupId)}/devices/${_segment(deviceId)}',
    );
  }

  @override
  Future<List<ProjectRoleBinding>> listProjectRoles(String projectId) async {
    final body = await _request(
      'GET',
      '/v1/projects/${_segment(projectId)}/roles',
    );
    return _bindingList(body)
        .map((item) => ProjectRoleBinding.fromJson(_asMap(item)))
        .toList(growable: false);
  }

  @override
  Future<void> putProjectRole(
    String projectId,
    RoleCreateRequest request,
  ) async {
    await _request(
      'POST',
      '/v1/projects/${_segment(projectId)}/roles',
      body: request.toJson(),
    );
  }

  @override
  Future<void> deleteProjectRole(String projectId, String bindingId) async {
    await _request(
      'DELETE',
      '/v1/projects/${_segment(projectId)}/roles/${_segment(bindingId)}',
    );
  }

  @override
  Future<List<GroupRoleBinding>> listGroupRoles(
    String projectId,
    String groupId,
  ) async {
    final body = await _request(
      'GET',
      '/v1/projects/${_segment(projectId)}/groups/${_segment(groupId)}/roles',
    );
    return _bindingList(body)
        .map((item) => GroupRoleBinding.fromJson(_asMap(item)))
        .toList(growable: false);
  }

  @override
  Future<void> putGroupRole(
    String projectId,
    String groupId,
    RoleCreateRequest request,
  ) async {
    await _request(
      'POST',
      '/v1/projects/${_segment(projectId)}/groups/${_segment(groupId)}/roles',
      body: request.toJson(),
    );
  }

  @override
  Future<void> deleteGroupRole(
    String projectId,
    String groupId,
    String bindingId,
  ) async {
    await _request(
      'DELETE',
      '/v1/projects/${_segment(projectId)}/groups/'
          '${_segment(groupId)}/roles/${_segment(bindingId)}',
    );
  }

  @override
  Future<Challenge> createRegistrationChallenge(
    String projectId, {
    required String platform,
  }) async {
    final body = await _request(
      'POST',
      '/v1/projects/${_segment(projectId)}/devices/registration/challenge',
      body: {'platform': platform},
    );
    return Challenge.fromJson(_asMap(body));
  }

  @override
  Future<Device> verifyRegistration(
    String projectId,
    RegistrationVerifyRequest request,
  ) async {
    final body = await _request(
      'POST',
      '/v1/projects/${_segment(projectId)}/devices/registration/verify',
      body: request.toJson(),
    );
    return Device.fromJson(_asMap(body));
  }

  @override
  Future<Challenge> createProofChallenge(
    String projectId,
    String deviceId,
  ) async {
    final body = await _request(
      'POST',
      '/v1/projects/${_segment(projectId)}/devices/${_segment(deviceId)}/challenge',
    );
    return Challenge.fromJson(_asMap(body));
  }

  @override
  Future<void> verifyProof(
    String projectId,
    String deviceId,
    ProofVerifyRequest request,
  ) async {
    await _request(
      'POST',
      '/v1/projects/${_segment(projectId)}/devices/${_segment(deviceId)}/verify',
      body: request.toJson(),
    );
  }

  @override
  Future<AttestationCapabilities> attestationCapabilities(
    String projectId,
  ) async {
    final body = await _request(
      'GET',
      '/v1/projects/${_segment(projectId)}/attestation/capabilities',
    );
    return AttestationCapabilities.fromJson(_asMap(body));
  }

  @override
  Future<List<AttestationRecord>> attestations(
    String projectId,
    String deviceId,
  ) async {
    final body = await _request(
      'GET',
      '/v1/projects/${_segment(projectId)}/devices/${_segment(deviceId)}/attestation',
    );
    return _asList(body)
        .map((item) => AttestationRecord.fromJson(_asMap(item)))
        .toList(growable: false);
  }

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{'Accept': 'application/json'};
    final encoded = body == null ? null : jsonEncode(body);
    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }
    if (authenticated) {
      headers['Authorization'] = 'Bearer ${_requireAccessToken()}';
    }

    var response = await _send(method, uri, headers, encoded);

    // Keycloak access tokens are short-lived. Refresh once and retry instead of
    // discarding the session on the first 401 caused by an expired token.
    if (response.statusCode == 401 &&
        authenticated &&
        _refreshAccessToken != null) {
      var refreshed = false;
      try {
        refreshed = await _refreshAccessToken();
      } on Object {
        refreshed = false;
      }
      if (refreshed) {
        headers['Authorization'] = 'Bearer ${_requireAccessToken()}';
        response = await _send(method, uri, headers, encoded);
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } on FormatException {
        throw FormatException(
          'Invalid JSON from Gorape API (${response.statusCode}).',
        );
      }
    }
    throw _mapError(response);
  }

  String _requireAccessToken() {
    final token = _accessTokenProvider();
    if (token == null || token.isEmpty) {
      throw const AuthException(
        'ログインセッションがありません。もう一度ログインしてください。',
        code: 'missing_access_token',
      );
    }
    return token;
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? encoded,
  ) async {
    try {
      return await switch (method) {
        'GET' => _http.get(uri, headers: headers),
        'POST' => _http.post(uri, headers: headers, body: encoded),
        'PATCH' => _http.patch(uri, headers: headers, body: encoded),
        'DELETE' => _http.delete(uri, headers: headers, body: encoded),
        _ => throw UnsupportedError('Unsupported HTTP method: $method'),
      }.timeout(timeout);
    } on TimeoutException {
      throw const NetworkException(
        'Gorape APIへの接続がタイムアウトしました。',
        code: 'timeout',
        guidance: 'Dockerコンテナとネットワーク接続を確認してください。',
      );
    } on http.ClientException catch (error) {
      throw NetworkException(
        'Gorape APIへ接続できませんでした。',
        code: 'network_error',
        guidance: '${error.message}\nAPI URLとDocker環境を確認してください。',
      );
    }
  }

  AppException _mapError(http.Response response) {
    var code = 'http_${response.statusCode}';
    var message = 'Gorape API returned HTTP ${response.statusCode}.';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final error = ApiErrorBody.fromJson(decoded);
        code = error.code;
        message = error.message;
      }
    } on FormatException {
      // Keep the generic message when the server did not return JSON.
    }

    if (response.statusCode == 401) {
      return AuthException(
        message,
        code: code,
        guidance:
            'アクセストークンの有効期限、Issuer、Audience（gorape-api）を確認してください。'
            '初回起動時は、このIssuerのGorapeプロジェクトがbootstrap済みかも確認してください。',
      );
    }
    if (response.statusCode == 422) {
      return ApiException(
        message,
        statusCode: 422,
        code: code,
        guidance: 'Attestationの信頼アンカー設定または端末の互換性を確認してください。',
      );
    }
    if (response.statusCode == 403) {
      return ApiException(
        message,
        statusCode: 403,
        code: code,
        guidance:
            'Keycloakトークンのロール表示と、Gorape DBのproject/groupロール付与は別に管理されています。'
            '管理操作にはGorape側でadmin/editorの付与が必要です。',
      );
    }
    return ApiException(message, statusCode: response.statusCode, code: code);
  }

  static String _segment(String value) => Uri.encodeComponent(value);

  static List<dynamic> _asList(Object? value) {
    if (value is List) return value;
    throw const FormatException('Expected a JSON array from Gorape.');
  }

  static List<dynamic> _bindingList(Object? value) {
    // The current server wraps bindings in an object. Keep accepting a bare
    // array for compatibility with older Gorape API versions.
    if (value is List) return value;
    return _asList(_asMap(value)['bindings']);
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Expected a JSON object from Gorape.');
  }
}
