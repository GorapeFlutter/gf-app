/// Android OS support and service registration for gf-app's credential provider.
///
/// This deliberately does not claim whether the user has enabled or preferred
/// the provider; Android does not expose that state through a public API.
final class CredentialProviderStatus {
  /// GF-01241 — Creates a platform credential-provider status value.
  const CredentialProviderStatus({
    required this.apiLevel,
    required this.supported,
    required this.serviceRegistered,
  });

  final int apiLevel;
  final bool supported;
  final bool serviceRegistered;

  /// GF-01185 — Parses the native Android credential-provider status.
  factory CredentialProviderStatus.fromMap(Map<Object?, Object?> map) =>
      CredentialProviderStatus(
        apiLevel: map['apiLevel'] as int? ?? 0,
        supported: map['supported'] as bool? ?? false,
        serviceRegistered: map['serviceRegistered'] as bool? ?? false,
      );
}
