/// Errors surfaced by the Flutter client.
///
/// Messages intentionally avoid tokens, key material, and raw signatures.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.guidance});

  final String message;
  final String? code;
  final String? guidance;

  String get title;

  @override
  String toString() => '$runtimeType($code): $message';
}

class ConfigurationException extends AppException {
  const ConfigurationException(super.message, {super.code, super.guidance});

  @override
  String get title => '設定エラー';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.guidance});

  @override
  String get title => 'ネットワークエラー';
}

class ApiException extends AppException {
  const ApiException(
    super.message, {
    required this.statusCode,
    super.code,
    super.guidance,
  });

  final int statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isUnprocessable => statusCode == 422;

  @override
  String get title => switch (statusCode) {
    400 => 'リクエストが不正です',
    401 => '認証が必要です',
    403 => '権限がありません',
    404 => '見つかりません',
    422 => '検証に失敗しました',
    >= 500 => 'サーバーエラー',
    _ => 'APIエラー',
  };
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.guidance});

  @override
  String get title => 'ログインエラー';
}

class AuthCancelledException extends AuthException {
  const AuthCancelledException()
    : super('ログインがキャンセルされました。', code: 'auth_cancelled');

  @override
  String get title => 'ログインをキャンセルしました';
}

class OidcUnsupportedException extends AppException {
  const OidcUnsupportedException(super.message, {super.guidance});

  @override
  String get title => 'このOSではログイン未対応です';
}

class DeviceKeyUnsupportedException extends AppException {
  const DeviceKeyUnsupportedException(
    super.message, {
    required this.platform,
    super.guidance,
  });

  final String platform;

  @override
  String get title => 'OS保護鍵を利用できません';
}

class AttestationNotConfiguredException extends AppException {
  const AttestationNotConfiguredException(
    super.message, {
    super.code,
    super.guidance,
  });

  @override
  String get title => 'Attestationが未設定です';
}

class BackendAttestationUnsupportedException extends AppException {
  const BackendAttestationUnsupportedException(
    super.message, {
    required this.platform,
    super.code,
    super.guidance,
  });

  final String platform;

  @override
  String get title => 'バックエンドが未対応です';
}

class DeviceKeyUnavailableException extends AppException {
  const DeviceKeyUnavailableException(super.message, {super.guidance});

  @override
  String get title => 'デバイス鍵が見つかりません';
}

class ChallengeException extends AppException {
  const ChallengeException(super.message, {super.code, super.guidance});

  @override
  String get title => 'チャレンジが無効です';
}

class PolicyApiUnavailableException extends AppException {
  const PolicyApiUnavailableException(super.message, {super.guidance});

  @override
  String get title => 'ポリシーAPIは未提供です';
}

class OperationCancelledException extends AppException {
  const OperationCancelledException() : super('操作をキャンセルしました。');

  @override
  String get title => 'キャンセルしました';
}

class UnknownAppException extends AppException {
  const UnknownAppException(super.message, {super.code, super.guidance});

  @override
  String get title => 'エラーが発生しました';
}
