class AuthSupport {
  const AuthSupport({required this.isSupported, this.unsupportedReason});

  final bool isSupported;
  final String? unsupportedReason;
}
