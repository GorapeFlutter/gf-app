import 'dart:convert';
import 'dart:math';

import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../entity/model/platform.dart';

/// Executes WebAuthn ceremonies through the OS/browser credential provider.
///
/// This layer preserves the full attestation/assertion response. It does not
/// infer hardware backing or trust from the requested conveyance preference;
/// Gorape is authoritative for verification and policy.
abstract interface class PasskeyRepository {
  Future<Map<String, dynamic>> register(Map<String, dynamic> publicKeyOptions);

  Future<Map<String, dynamic>> authenticate(
    Map<String, dynamic> publicKeyOptions,
  );
}

abstract interface class BrowserPasskeyRepository implements PasskeyRepository {
  Future<Map<String, String>> registerInBrowser({
    required String browserUrl,
    required String browserApiOrigin,
    required String challengeId,
  });

  Future<void> authenticateInBrowser({
    required String browserUrl,
    required String browserApiOrigin,
    required String challengeId,
  });
}

final class PasskeyRepositoryImpl implements PasskeyRepository {
  PasskeyRepositoryImpl({PasskeyAuthenticatorInterface? authenticator})
    : _authenticator = authenticator ?? PasskeyAuthenticator();

  final PasskeyAuthenticatorInterface _authenticator;

  @override
  Future<Map<String, dynamic>> register(
    Map<String, dynamic> publicKeyOptions,
  ) async {
    _validateRegistrationOptions(publicKeyOptions);
    final request = RegisterRequestType.fromJson(publicKeyOptions);
    final credential = await _authenticator.register(request);
    if (credential.id.isEmpty ||
        credential.clientDataJSON.isEmpty ||
        credential.attestationObject.isEmpty) {
      throw const FormatException(
        'Authenticator returned an incomplete WebAuthn attestation response.',
      );
    }
    return credential.toJson();
  }

  @override
  Future<Map<String, dynamic>> authenticate(
    Map<String, dynamic> publicKeyOptions,
  ) async {
    _validateAuthenticationOptions(publicKeyOptions);
    final request = AuthenticateRequestType.fromJson(
      publicKeyOptions,
      preferImmediatelyAvailableCredentials: false,
    );
    final credential = await _authenticator.authenticate(request);
    if (credential.id.isEmpty ||
        credential.clientDataJSON.isEmpty ||
        credential.authenticatorData.isEmpty ||
        credential.signature.isEmpty) {
      throw const FormatException(
        'Authenticator returned an incomplete WebAuthn assertion.',
      );
    }
    return credential.toJson();
  }

  static void _validateRegistrationOptions(Map<String, dynamic> options) {
    final rp = options['rp'];
    final user = options['user'];
    final challenge = options['challenge'];
    final attestation = options['attestation'];
    if (rp is! Map ||
        user is! Map ||
        challenge is! String ||
        challenge.isEmpty) {
      throw const FormatException(
        'Invalid WebAuthn credential creation options.',
      );
    }
    if (attestation is! String ||
        !const {
          'none',
          'indirect',
          'direct',
          'enterprise',
        }.contains(attestation)) {
      throw const FormatException(
        'Gorape must explicitly select an attestation conveyance preference.',
      );
    }
    // Ensure options can be serialized as JSON before passing them through the
    // platform-channel implementation.
    jsonEncode(options);
  }

  static void _validateAuthenticationOptions(Map<String, dynamic> options) {
    final challenge = options['challenge'];
    final rpId = options['rpId'];
    if (challenge is! String ||
        challenge.isEmpty ||
        rpId is! String ||
        rpId.isEmpty) {
      throw const FormatException(
        'Invalid WebAuthn credential request options.',
      );
    }
    jsonEncode(options);
  }
}

typedef PasskeyPortalLauncher =
    Future<String> Function({required String url, required String callbackUrl});

/// Linux does not have a native Flutter passkeys plugin. It uses a one-use
/// Gorape RP portal in the system browser so the browser's standard WebAuthn
/// implementation can use its configured platform or roaming authenticator.
final class LinuxBrowserPasskeyRepository implements BrowserPasskeyRepository {
  LinuxBrowserPasskeyRepository({PasskeyPortalLauncher? launcher})
    : _launcher = launcher ?? _launchPortal;

  static const callbackHost = '127.0.0.1';
  static const callbackPort = 8402;
  static const callbackPath = '/passkey-result';

  final PasskeyPortalLauncher _launcher;

  @override
  Future<Map<String, dynamic>> register(
    Map<String, dynamic> publicKeyOptions,
  ) => throw UnsupportedError('Linux WebAuthn uses Gorape RP browser portal');

  @override
  Future<Map<String, dynamic>> authenticate(
    Map<String, dynamic> publicKeyOptions,
  ) => throw UnsupportedError('Linux WebAuthn uses Gorape RP browser portal');

  @override
  Future<Map<String, String>> registerInBrowser({
    required String browserUrl,
    required String browserApiOrigin,
    required String challengeId,
  }) => _runPortal(
    browserUrl: browserUrl,
    browserApiOrigin: browserApiOrigin,
    challengeId: challengeId,
    ceremony: 'registration',
  );

  @override
  Future<void> authenticateInBrowser({
    required String browserUrl,
    required String browserApiOrigin,
    required String challengeId,
  }) async {
    await _runPortal(
      browserUrl: browserUrl,
      browserApiOrigin: browserApiOrigin,
      challengeId: challengeId,
      ceremony: 'authentication',
    );
  }

  Future<Map<String, String>> _runPortal({
    required String browserUrl,
    required String browserApiOrigin,
    required String challengeId,
    required String ceremony,
  }) async {
    final portal = Uri.tryParse(browserUrl);
    final apiOrigin = Uri.tryParse(browserApiOrigin);
    if (portal == null ||
        !portal.hasScheme ||
        portal.host.isEmpty ||
        (portal.scheme != 'https' &&
            !(portal.scheme == 'http' &&
                (portal.host == 'localhost' || portal.host == '127.0.0.1')))) {
      throw const FormatException(
        'Gorape returned an invalid browser portal URL.',
      );
    }
    if (apiOrigin == null ||
        apiOrigin.host.isEmpty ||
        apiOrigin.path.isNotEmpty ||
        apiOrigin.query.isNotEmpty ||
        apiOrigin.fragment.isNotEmpty ||
        (apiOrigin.scheme != 'https' &&
            !(apiOrigin.scheme == 'http' &&
                (apiOrigin.host == 'localhost' ||
                    apiOrigin.host == '127.0.0.1')))) {
      throw const FormatException(
        'Gorape returned an invalid browser API origin.',
      );
    }
    final state = _randomState();
    final callback = Uri(
      scheme: 'http',
      host: callbackHost,
      port: callbackPort,
      path: callbackPath,
    ).replace(queryParameters: {'state': state});
    final fragment = Uri(
      queryParameters: {
        'challenge_id': challengeId,
        'api_origin': apiOrigin.origin,
        'ceremony': ceremony,
        'state': state,
        'return_uri': callback.toString(),
      },
    ).query;
    final response = await _launcher(
      url: portal.replace(fragment: fragment).toString(),
      callbackUrl: callback.toString(),
    );
    final result = Uri.parse(response);
    if (result.scheme != callback.scheme ||
        result.host != callback.host ||
        result.port != callback.port ||
        result.path != callback.path ||
        result.queryParameters['state'] != state ||
        result.queryParameters['status'] != 'verified') {
      throw const FormatException(
        'Gorape browser passkey ceremony did not complete.',
      );
    }
    if (ceremony == 'registration' &&
        (result.queryParameters['device_id']?.isEmpty ?? true)) {
      throw const FormatException(
        'Gorape browser registration returned no device ID.',
      );
    }
    return result.queryParameters;
  }

  static Future<String> _launchPortal({
    required String url,
    required String callbackUrl,
  }) => FlutterWebAuth2.authenticate(
    url: url,
    callbackUrlScheme: callbackUrl,
    options: const FlutterWebAuth2Options(useWebview: false, timeout: 300),
  );

  static String _randomState() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}

PasskeyRepository newPasskeyRepository(RuntimePlatform platform) =>
    platform == RuntimePlatform.linux
    ? LinuxBrowserPasskeyRepository()
    : PasskeyRepositoryImpl();
