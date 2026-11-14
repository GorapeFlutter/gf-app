class AuthSupport {
  /// GF-00260 — Initializes AuthSupport.
  const AuthSupport({required this.isSupported, this.unsupportedReason});

  final bool isSupported;
  final String? unsupportedReason;
}
