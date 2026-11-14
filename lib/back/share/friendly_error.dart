import 'error.dart';

/// A presentation-friendly view of an arbitrary error.
class FriendlyError {
  /// GF-00662 — Initializes FriendlyError.
  const FriendlyError({
    required this.title,
    required this.message,
    this.guidance,
    this.canRetry = true,
  });

  final String title;
  final String message;
  final String? guidance;
  final bool canRetry;

  /// GF-00663 — Handles from in FriendlyError.
  static FriendlyError from(Object error) {
    if (error is AppException) {
      return FriendlyError(
        title: error.title,
        message: error.message,
        guidance: error.guidance,
        canRetry:
            error is! DeviceKeyUnsupportedException &&
            error is! OidcUnsupportedException &&
            error is! PolicyApiUnavailableException,
      );
    }
    if (error is FormatException) {
      return FriendlyError(
        title: 'データ形式エラー',
        message: 'サーバーの応答を解釈できませんでした。',
        guidance: error.message,
      );
    }
    return FriendlyError(title: '予期しないエラー', message: error.toString());
  }
}
