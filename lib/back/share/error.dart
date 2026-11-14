/// Errors surfaced by the Flutter client.
///
/// Messages intentionally avoid tokens, key material, and raw signatures.
sealed class AppException implements Exception {
  /// GF-00627 — Initializes AppException.
  const AppException(this.message, {this.code, this.guidance});

  final String message;
  final String? code;
  final String? guidance;

  /// GF-00628 — Computes AppException.title.
  String get title;

  /// GF-00629 — Handles to string in AppException.
  @override
  String toString() => '$runtimeType($code): $message';
}

class ConfigurationException extends AppException {
  /// GF-00630 — Initializes ConfigurationException.
  const ConfigurationException(super.message, {super.code, super.guidance});

  /// GF-00631 — Computes ConfigurationException.title.
  @override
  String get title => '設定エラー';
}

class NetworkException extends AppException {
  /// GF-00632 — Initializes NetworkException.
  const NetworkException(super.message, {super.code, super.guidance});

  /// GF-00633 — Computes NetworkException.title.
  @override
  String get title => 'ネットワークエラー';
}

class ApiException extends AppException {
  /// GF-00634 — Initializes ApiException.
  const ApiException(
    super.message, {
    required this.statusCode,
    super.code,
    super.guidance,
  });

  final int statusCode;

  /// GF-00635 — Computes ApiException.isUnauthorized.
  bool get isUnauthorized => statusCode == 401;

  /// GF-00636 — Computes ApiException.isForbidden.
  bool get isForbidden => statusCode == 403;

  /// GF-00637 — Computes ApiException.isNotFound.
  bool get isNotFound => statusCode == 404;

  /// GF-00638 — Computes ApiException.isUnprocessable.
  bool get isUnprocessable => statusCode == 422;

  /// GF-00639 — Computes ApiException.title.
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
  /// GF-00640 — Initializes AuthException.
  const AuthException(super.message, {super.code, super.guidance});

  /// GF-00641 — Computes AuthException.title.
  @override
  String get title => 'ログインエラー';
}

class AuthCancelledException extends AuthException {
  /// GF-00642 — Initializes AuthCancelledException.
  const AuthCancelledException()
    : super('ログインがキャンセルされました。', code: 'auth_cancelled');

  /// GF-00643 — Computes AuthCancelledException.title.
  @override
  String get title => 'ログインをキャンセルしました';
}

class OidcUnsupportedException extends AppException {
  /// GF-00644 — Initializes OidcUnsupportedException.
  const OidcUnsupportedException(super.message, {super.guidance});

  /// GF-00645 — Computes OidcUnsupportedException.title.
  @override
  String get title => 'このOSではログイン未対応です';
}

class DeviceKeyUnsupportedException extends AppException {
  /// GF-00646 — Initializes DeviceKeyUnsupportedException.
  const DeviceKeyUnsupportedException(
    super.message, {
    required this.platform,
    super.guidance,
  });

  final String platform;

  /// GF-00647 — Computes DeviceKeyUnsupportedException.title.
  @override
  String get title => 'OS保護鍵を利用できません';
}

class AttestationNotConfiguredException extends AppException {
  /// GF-00648 — Initializes AttestationNotConfiguredException.
  const AttestationNotConfiguredException(
    super.message, {
    super.code,
    super.guidance,
  });

  /// GF-00649 — Computes AttestationNotConfiguredException.title.
  @override
  String get title => 'Attestationが未設定です';
}

class BackendAttestationUnsupportedException extends AppException {
  /// GF-00650 — Initializes BackendAttestationUnsupportedException.
  const BackendAttestationUnsupportedException(
    super.message, {
    required this.platform,
    super.code,
    super.guidance,
  });

  final String platform;

  /// GF-00651 — Computes BackendAttestationUnsupportedException.title.
  @override
  String get title => 'バックエンドが未対応です';
}

class DeviceKeyUnavailableException extends AppException {
  /// GF-00652 — Initializes DeviceKeyUnavailableException.
  const DeviceKeyUnavailableException(super.message, {super.guidance});

  /// GF-00653 — Computes DeviceKeyUnavailableException.title.
  @override
  String get title => 'デバイス鍵が見つかりません';
}

class ChallengeException extends AppException {
  /// GF-00654 — Initializes ChallengeException.
  const ChallengeException(super.message, {super.code, super.guidance});

  /// GF-00655 — Computes ChallengeException.title.
  @override
  String get title => 'チャレンジが無効です';
}

class PolicyApiUnavailableException extends AppException {
  /// GF-00656 — Initializes PolicyApiUnavailableException.
  const PolicyApiUnavailableException(super.message, {super.guidance});

  /// GF-00657 — Computes PolicyApiUnavailableException.title.
  @override
  String get title => 'ポリシーAPIは未提供です';
}

class OperationCancelledException extends AppException {
  /// GF-00658 — Initializes OperationCancelledException.
  const OperationCancelledException() : super('操作をキャンセルしました。');

  /// GF-00659 — Computes OperationCancelledException.title.
  @override
  String get title => 'キャンセルしました';
}

class UnknownAppException extends AppException {
  /// GF-00660 — Initializes UnknownAppException.
  const UnknownAppException(super.message, {super.code, super.guidance});

  /// GF-00661 — Computes UnknownAppException.title.
  @override
  String get title => 'エラーが発生しました';
}
