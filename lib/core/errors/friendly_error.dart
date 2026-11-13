import 'app_exception.dart';

/// A presentation-friendly view of an arbitrary error.
class FriendlyError {
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
