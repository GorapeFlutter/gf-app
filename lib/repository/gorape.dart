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
  /// GF-00489 — Handles health in GorapeApi.
  Future<Map<String, dynamic>> health();

  /// GF-00490 — Handles list projects in GorapeApi.
  Future<List<Project>> listProjects();

  /// GF-00491 — Handles get project in GorapeApi.
  Future<Project> getProject(String projectId);

  /// GF-00492 — Handles list devices in GorapeApi.
  Future<List<Device>> listDevices(String projectId);

  /// GF-00493 — Handles get device in GorapeApi.
  Future<Device> getDevice(String projectId, String deviceId);

  /// GF-00494 — Handles revoke device in GorapeApi.
  Future<void> revokeDevice(String projectId, String deviceId);

  /// GF-00495 — Handles list groups in GorapeApi.
  Future<List<Group>> listGroups(String projectId);

  /// GF-00496 — Handles get group in GorapeApi.
  Future<Group> getGroup(String projectId, String groupId);

  /// GF-00497 — Handles create group in GorapeApi.
  Future<Group> createGroup(String projectId, GroupCreateRequest request);

  /// GF-00498 — Handles update group in GorapeApi.
  Future<Group> updateGroup(
    String projectId,
    String groupId,
    GroupUpdateRequest request,
  );

  /// GF-00499 — Handles delete group in GorapeApi.
  Future<void> deleteGroup(String projectId, String groupId);

  /// GF-00500 — Handles list group devices in GorapeApi.
  Future<List<Device>> listGroupDevices(String projectId, String groupId);

  /// GF-00501 — Handles bind device to group in GorapeApi.
  Future<void> bindDeviceToGroup(
    String projectId,
    String groupId,
    String deviceId,
  );

  /// GF-00502 — Handles unbind device from group in GorapeApi.
  Future<void> unbindDeviceFromGroup(
    String projectId,
    String groupId,
    String deviceId,
  );

  /// GF-00503 — Handles list project roles in GorapeApi.
  Future<List<ProjectRoleBinding>> listProjectRoles(String projectId);

  /// GF-00504 — Handles put project role in GorapeApi.
  Future<void> putProjectRole(String projectId, RoleCreateRequest request);

  /// GF-00505 — Handles delete project role in GorapeApi.
  Future<void> deleteProjectRole(String projectId, String bindingId);

  /// GF-00506 — Handles list group roles in GorapeApi.
  Future<List<GroupRoleBinding>> listGroupRoles(
    String projectId,
    String groupId,
  );

  /// GF-00507 — Handles put group role in GorapeApi.
  Future<void> putGroupRole(
    String projectId,
    String groupId,
    RoleCreateRequest request,
  );

  /// GF-00508 — Handles delete group role in GorapeApi.
  Future<void> deleteGroupRole(
    String projectId,
    String groupId,
    String bindingId,
  );

  /// GF-00509 — Handles create registration challenge in GorapeApi.
  Future<Challenge> createRegistrationChallenge(
    String projectId, {
    required String platform,
  });

  /// GF-00510 — Handles verify registration in GorapeApi.
  Future<Device> verifyRegistration(
    String projectId,
    RegistrationVerifyRequest request,
  );

  /// GF-00511 — Handles create proof challenge in GorapeApi.
  Future<Challenge> createProofChallenge(String projectId, String deviceId);

  /// GF-00512 — Handles verify proof in GorapeApi.
  Future<void> verifyProof(
    String projectId,
    String deviceId,
    ProofVerifyRequest request,
  );

  /// GF-00513 — Handles attestation capabilities in GorapeApi.
  Future<AttestationCapabilities> attestationCapabilities(String projectId);

  /// GF-00514 — Handles attestations in GorapeApi.
  Future<List<AttestationRecord>> attestations(
    String projectId,
    String deviceId,
  );
}

/// GF-00515 — Creates an instance for new gorape api.
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
  /// GF-00516 — Initializes GorapeApiClient.
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

  /// GF-00517 — Handles normalize base url in GorapeApiClient.
  static String _normalizeBaseUrl(String value) {
    var base = value.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return base;
  }

  /// GF-00518 — Handles health in GorapeApiClient.
  @override
  Future<Map<String, dynamic>> health() async {
    final body = await _request('GET', '/health', authenticated: false);
    return body is Map<String, dynamic> ? body : const {};
  }

  /// GF-00519 — Handles list projects in GorapeApiClient.
  @override
  Future<List<Project>> listProjects() async {
    final body = await _request('GET', '/v1/projects');
    return _asList(body)
        .map(
          /* GF-00520 — Runs an inline callback in GorapeApiClient.listProjects. */ (
            item,
          ) => Project.fromJson(_asMap(item)),
        )
        .toList(growable: false);
  }

  /// GF-00521 — Handles get project in GorapeApiClient.
  @override
  Future<Project> getProject(String projectId) async {
    final body = await _request('GET', '/v1/projects/${_segment(projectId)}');
    return Project.fromJson(_asMap(body));
  }

  /// GF-00522 — Handles list devices in GorapeApiClient.
  @override
  Future<List<Device>> listDevices(String projectId) async {
    final body = await _request(
      'GET',
      '/v1/projects/${_segment(projectId)}/devices',
    );
    return _asList(body)
        .map(
          /* GF-00523 — Runs an inline callback in GorapeApiClient.listDevices. */ (
            item,
          ) => Device.fromJson(_asMap(item)),
        )
        .toList(growable: false);
  }

  /// GF-00524 — Handles get device in GorapeApiClient.
  @override
  Future<Device> getDevice(String projectId, String deviceId) async {
    final body = await _request(
      'GET',
      '/v1/projects/${_segment(projectId)}/devices/${_segment(deviceId)}',
    );
    return Device.fromJson(_asMap(body));
  }

  /// GF-00525 — Handles revoke device in GorapeApiClient.
  @override
  Future<void> revokeDevice(String projectId, String deviceId) async {
    await _request(
      'DELETE',
      '/v1/projects/${_segment(projectId)}/devices/${_segment(deviceId)}',
    );
  }

  /// GF-00526 — Handles list groups in GorapeApiClient.
  @override
  Future<List<Group>> listGroups(String projectId) async {
    final body = await _request(
      'GET',
      '/v1/projects/${_segment(projectId)}/groups',
    );
    return _asList(body)
        .map(
          /* GF-00527 — Runs an inline callback in GorapeApiClient.listGroups. */ (
            item,
          ) => Group.fromJson(_asMap(item)),
        )
        .toList(growable: false);
  }

  /// GF-00528 — Handles get group in GorapeApiClient.
  @override
  Future<Group> getGroup(String projectId, String groupId) async {
    final body = await _request(
      'GET',
      '/v1/projects/${_segment(projectId)}/groups/${_segment(groupId)}',
    );
    return Group.fromJson(_asMap(body));
  }

  /// GF-00529 — Handles create group in GorapeApiClient.
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

  /// GF-00530 — Handles update group in GorapeApiClient.
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

  /// GF-00531 — Handles delete group in GorapeApiClient.
  @override
  Future<void> deleteGroup(String projectId, String groupId) async {
    await _request(
      'DELETE',
      '/v1/projects/${_segment(projectId)}/groups/${_segment(groupId)}',
    );
  }

  /// GF-00532 — Handles list group devices in GorapeApiClient.
  @override
  Future<List<Device>> listGroupDevices(
    String projectId,
    String groupId,
  ) async {
    final body = await _request(
      'GET',
      '/v1/projects/${_segment(projectId)}/groups/${_segment(groupId)}/devices',
    );
    return _asList(body)
        .map(
          /* GF-00533 — Runs an inline callback in GorapeApiClient.listGroupDevices. */ (
            item,
          ) => Device.fromJson(_asMap(item)),
        )
        .toList(growable: false);
  }

  /// GF-00534 — Handles bind device to group in GorapeApiClient.
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

  /// GF-00535 — Handles unbind device from group in GorapeApiClient.
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

  /// GF-00536 — Handles list project roles in GorapeApiClient.
  @override
  Future<List<ProjectRoleBinding>> listProjectRoles(String projectId) async {
    final body = await _request(
      'GET',
      '/v1/projects/${_segment(projectId)}/roles',
    );
    return _bindingList(body)
        .map(
          /* GF-00537 — Runs an inline callback in GorapeApiClient.listProjectRoles. */ (
            item,
          ) => ProjectRoleBinding.fromJson(_asMap(item)),
        )
        .toList(growable: false);
  }

  /// GF-00538 — Handles put project role in GorapeApiClient.
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

  /// GF-00539 — Handles delete project role in GorapeApiClient.
  @override
  Future<void> deleteProjectRole(String projectId, String bindingId) async {
    await _request(
      'DELETE',
      '/v1/projects/${_segment(projectId)}/roles/${_segment(bindingId)}',
    );
  }

  /// GF-00540 — Handles list group roles in GorapeApiClient.
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
        .map(
          /* GF-00541 — Runs an inline callback in GorapeApiClient.listGroupRoles. */ (
            item,
          ) => GroupRoleBinding.fromJson(_asMap(item)),
        )
        .toList(growable: false);
  }

  /// GF-00542 — Handles put group role in GorapeApiClient.
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

  /// GF-00543 — Handles delete group role in GorapeApiClient.
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

  /// GF-00544 — Handles create registration challenge in GorapeApiClient.
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

  /// GF-00545 — Handles verify registration in GorapeApiClient.
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

  /// GF-00546 — Handles create proof challenge in GorapeApiClient.
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

  /// GF-00547 — Handles verify proof in GorapeApiClient.
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

  /// GF-00548 — Handles attestation capabilities in GorapeApiClient.
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

  /// GF-00549 — Handles attestations in GorapeApiClient.
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
        .map(
          /* GF-00550 — Runs an inline callback in GorapeApiClient.attestations. */ (
            item,
          ) => AttestationRecord.fromJson(_asMap(item)),
        )
        .toList(growable: false);
  }

  /// GF-00551 — Handles request in GorapeApiClient.
  /// GF-00003 — Sends an authenticated request and retries once after refresh.
  Future<Object?> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    // GF-02012 — Build the URI, JSON payload, and authentication headers.
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{'Accept': 'application/json'};
    final encoded = body == null ? null : jsonEncode(body);
    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }
    if (authenticated) {
      headers['Authorization'] = 'Bearer ${_requireAccessToken()}';
    }

    // GF-02013 — Send the initial API request.
    var response = await _send(method, uri, headers, encoded);

    // Keycloak access tokens are short-lived. Refresh once and retry instead of
    // discarding the session on the first 401 caused by an expired token.
    if (response.statusCode == 401 &&
        authenticated &&
        _refreshAccessToken != null) {
      // GF-02014 — Refresh an expired access token at most once.
      var refreshed = false;
      try {
        refreshed = await _refreshAccessToken();
      } on Object {
        refreshed = false;
      }
      if (refreshed) {
        // GF-02015 — Retry the original request once with the refreshed token.
        headers['Authorization'] = 'Bearer ${_requireAccessToken()}';
        response = await _send(method, uri, headers, encoded);
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) return null;
      try {
        // GF-02016 — Decode a successful JSON response for the repository caller.
        return jsonDecode(response.body);
      } on FormatException {
        throw FormatException(
          'Invalid JSON from Gorape API (${response.statusCode}).',
        );
      }
    }
    // GF-02017 — Convert non-success HTTP responses into app-level exceptions.
    throw _mapError(response);
  }

  /// GF-00552 — Handles require access token in GorapeApiClient.
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

  /// GF-00553 — Handles send in GorapeApiClient.
  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? encoded,
  ) async {
    try {
      // GF-02018 — Dispatch the request using the selected HTTP verb.
      return await switch (method) {
        'GET' => _http.get(uri, headers: headers),
        'POST' => _http.post(uri, headers: headers, body: encoded),
        'PATCH' => _http.patch(uri, headers: headers, body: encoded),
        'DELETE' => _http.delete(uri, headers: headers, body: encoded),
        _ => throw UnsupportedError('Unsupported HTTP method: $method'),
      }.timeout(timeout);
    } on TimeoutException {
      // GF-02019 — Map transport timeouts to a user-facing network error.
      throw const NetworkException(
        'Gorape APIへの接続がタイムアウトしました。',
        code: 'timeout',
        guidance: 'Dockerコンテナとネットワーク接続を確認してください。',
      );
    } on http.ClientException catch (error) {
      // GF-02020 — Map client transport failures to a network error.
      throw NetworkException(
        'Gorape APIへ接続できませんでした。',
        code: 'network_error',
        guidance: '${error.message}\nAPI URLとDocker環境を確認してください。',
      );
    }
  }

  /// GF-00554 — Handles map error in GorapeApiClient.
  AppException _mapError(http.Response response) {
    var code = 'http_${response.statusCode}';
    var message = 'Gorape API returned HTTP ${response.statusCode}.';
    try {
      // GF-02021 — Prefer structured API error details when the body is JSON.
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final error = ApiErrorBody.fromJson(decoded);
        code = error.code;
        message = error.message;
      }
    } on FormatException {
      // Keep the generic message when the server did not return JSON.
    }

    // GF-02022 — Add authentication guidance for rejected credentials.
    if (response.statusCode == 401) {
      return AuthException(
        message,
        code: code,
        guidance:
            'アクセストークンの有効期限、Issuer、Audience（gorape-api）を確認してください。'
            '初回起動時は、このIssuerのGorapeプロジェクトがbootstrap済みかも確認してください。',
      );
    }
    // GF-02162 — Attach attestation-specific guidance to validation failures.
    if (response.statusCode == 422) {
      return ApiException(
        message,
        statusCode: 422,
        code: code,
        guidance: 'Attestationの信頼アンカー設定または端末の互換性を確認してください。',
      );
    }
    // GF-02163 — Explain that backend role bindings govern forbidden actions.
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

  /// GF-00555 — Handles segment in GorapeApiClient.
  static String _segment(String value) => Uri.encodeComponent(value);

  /// GF-00556 — Handles as list in GorapeApiClient.
  static List<dynamic> _asList(Object? value) {
    if (value is List) return value;
    throw const FormatException('Expected a JSON array from Gorape.');
  }

  /// GF-00557 — Handles binding list in GorapeApiClient.
  static List<dynamic> _bindingList(Object? value) {
    // The current server wraps bindings in an object. Keep accepting a bare
    // array for compatibility with older Gorape API versions.
    if (value is List) return value;
    return _asList(_asMap(value)['bindings']);
  }

  /// GF-00558 — Handles as map in GorapeApiClient.
  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Expected a JSON object from Gorape.');
  }
}
