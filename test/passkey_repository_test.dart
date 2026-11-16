import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/back/repository/passkey.dart';
import 'package:passkeys/types.dart';

class _Authenticator implements PasskeyAuthenticatorInterface {
  RegisterRequestType? registrationRequest;
  AuthenticateRequestType? authenticationRequest;

  @override
  Future<RegisterResponseType> register(RegisterRequestType request) async {
    registrationRequest = request;
    return const RegisterResponseType(
      id: 'credential-id',
      rawId: 'credential-id',
      clientDataJSON: 'client-data',
      attestationObject: 'attestation-object',
      transports: ['internal'],
    );
  }

  @override
  Future<AuthenticateResponseType> authenticate(
    AuthenticateRequestType request,
  ) async {
    authenticationRequest = request;
    return const AuthenticateResponseType(
      id: 'credential-id',
      rawId: 'credential-id',
      clientDataJSON: 'client-data',
      authenticatorData: 'authenticator-data',
      signature: 'signature',
      userHandle: 'user-handle',
    );
  }

  @override
  Future<void> signalUnknownCredential(
    SignalUnknownCredentialRequestType request,
  ) async {}

  @override
  Future<void> signalAllAcceptedCredentials(
    SignalAllAcceptedCredentialsRequestType request,
  ) async {}
}

void main() {
  group('PasskeyRepositoryImpl', () {
    test(
      'passes Gorape creation options and preserves attestation response',
      () async {
        final authenticator = _Authenticator();
        final repository = PasskeyRepositoryImpl(authenticator: authenticator);

        final credential = await repository.register({
          'challenge': 'Y2hhbGxlbmdl',
          'rp': {'id': 'gorapeflutter.site', 'name': 'Gorape'},
          'user': {
            'id': 'dXNlci0x',
            'name': 'user@example.test',
            'displayName': 'User',
          },
          'attestation': 'direct',
        });

        expect(authenticator.registrationRequest?.attestation, 'direct');
        expect(
          authenticator.registrationRequest?.relyingParty.id,
          'gorapeflutter.site',
        );
        expect(credential['id'], 'credential-id');
        expect(
          (credential['response'] as Map<String, dynamic>)['attestationObject'],
          'attestation-object',
        );
      },
    );

    test('requires an explicit attestation conveyance preference', () async {
      final authenticator = _Authenticator();
      final repository = PasskeyRepositoryImpl(authenticator: authenticator);

      expect(
        () => repository.register({
          'challenge': 'Y2hhbGxlbmdl',
          'rp': {'id': 'gorape.example', 'name': 'Gorape'},
          'user': {'id': 'dXNlci0x', 'name': 'user', 'displayName': 'User'},
        }),
        throwsFormatException,
      );
      expect(authenticator.registrationRequest, isNull);
    });

    test(
      'passes Gorape request options and returns assertion fields',
      () async {
        final authenticator = _Authenticator();
        final repository = PasskeyRepositoryImpl(authenticator: authenticator);

        final credential = await repository.authenticate({
          'challenge': 'Y2hhbGxlbmdl',
          'rpId': 'gorapeflutter.site',
          'userVerification': 'required',
        });

        expect(
          authenticator.authenticationRequest?.relyingPartyId,
          'gorapeflutter.site',
        );
        expect(credential['id'], 'credential-id');
        expect(
          (credential['response'] as Map<String, dynamic>)['signature'],
          'signature',
        );
      },
    );
  });

  group('LinuxBrowserPasskeyRepository', () {
    test(
      'uses the gf-app portal and validates its loopback completion',
      () async {
        String? openedUrl;
        final repository = LinuxBrowserPasskeyRepository(
          launcher: ({required url, required callbackUrl}) async {
            openedUrl = url;
            final portal = Uri.parse(url);
            final fragment = Uri.splitQueryString(portal.fragment);
            final callback = Uri.parse(fragment['return_uri']!);
            return callback
                .replace(
                  queryParameters: {
                    ...callback.queryParameters,
                    'status': 'verified',
                    'device_id': 'device-linux',
                  },
                )
                .toString();
          },
        );

        final result = await repository.registerInBrowser(
          browserUrl: 'https://app.gorapeflutter.site/passkey-ceremony.html',
          browserApiOrigin: 'https://api.gorapeflutter.site:8443',
          challengeId: 'challenge-1',
        );

        final fragment = Uri.splitQueryString(Uri.parse(openedUrl!).fragment);
        expect(result['device_id'], 'device-linux');
        expect(fragment['challenge_id'], 'challenge-1');
        expect(fragment['api_origin'], 'https://api.gorapeflutter.site:8443');
        expect(fragment['ceremony'], 'registration');
        expect(fragment['state'], isNotEmpty);
      },
    );
  });
}
