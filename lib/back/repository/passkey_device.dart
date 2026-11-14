import '../../entity/request/passkey.dart';
import '../../entity/response/passkey.dart';
import 'gorape.dart';

abstract interface class PasskeyDeviceRepository {
  Future<PasskeyRegistrationOptions> createRegistrationOptions(
    String projectId, {
    required String platform,
    required String displayName,
  });

  Future<PasskeyRegistrationResult> verifyRegistration(
    String projectId,
    PasskeyRegistrationVerifyRequest request,
  );

  Future<PasskeyRegistrationResult> registrationResult(
    String projectId,
    String deviceId,
  );

  Future<PasskeyAuthenticationOptions> createAuthenticationOptions(
    String projectId,
    String deviceId, {
    required String platform,
  });

  Future<void> verifyAuthentication(
    String projectId,
    String deviceId,
    PasskeyAuthenticationVerifyRequest request,
  );
}

final class PasskeyDeviceRepositoryImpl implements PasskeyDeviceRepository {
  const PasskeyDeviceRepositoryImpl(this._api);

  final GorapeApi _api;

  @override
  Future<PasskeyRegistrationOptions> createRegistrationOptions(
    String projectId, {
    required String platform,
    required String displayName,
  }) => _api.createPasskeyRegistrationOptions(
    projectId,
    platform: platform,
    displayName: displayName,
  );

  @override
  Future<PasskeyRegistrationResult> verifyRegistration(
    String projectId,
    PasskeyRegistrationVerifyRequest request,
  ) => _api.verifyPasskeyRegistration(projectId, request);

  @override
  Future<PasskeyRegistrationResult> registrationResult(
    String projectId,
    String deviceId,
  ) async {
    final device = await _api.getDevice(projectId, deviceId);
    final records = await _api.attestations(projectId, deviceId);
    if (records.isEmpty) {
      throw const FormatException('Verified attestation record is missing.');
    }
    final attestation = records.first;
    return PasskeyRegistrationResult(
      device: device,
      attestationType: attestation.attestationType,
      securityLevel: attestation.securityLevel,
      verifierVersion: attestation.verifierVersion,
    );
  }

  @override
  Future<PasskeyAuthenticationOptions> createAuthenticationOptions(
    String projectId,
    String deviceId, {
    required String platform,
  }) => _api.createPasskeyAuthenticationOptions(
    projectId,
    deviceId,
    platform: platform,
  );

  @override
  Future<void> verifyAuthentication(
    String projectId,
    String deviceId,
    PasskeyAuthenticationVerifyRequest request,
  ) => _api.verifyPasskeyAuthentication(projectId, deviceId, request);
}
