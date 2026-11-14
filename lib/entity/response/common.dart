class ApiErrorBody {
  /// GF-00394 — Initializes ApiErrorBody.
  const ApiErrorBody({required this.code, required this.message});

  final String code;
  final String message;

  /// GF-00395 — Initializes ApiErrorBody.fromJson.
  factory ApiErrorBody.fromJson(Map<String, dynamic> json) {
    return ApiErrorBody(
      code: json['code'] as String? ?? 'request_failed',
      message: json['message'] as String? ?? 'Request failed.',
    );
  }
}
