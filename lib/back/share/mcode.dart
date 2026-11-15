/// Stable event codes used by the gf-app diagnostic logger.
///
/// These are distinct from `MCODE-XXXXX`, which identifies localized UI copy.
class MCode {
  /// GF-01161 — Creates a logger MCode and its stable message.
  const MCode(this.code, this.message);

  final String code;
  final String message;

  /// GF-01162 — Pads the code for aligned structured log output.
  String padded(int width) => code.padRight(width);
}

abstract final class AppMCodes {
  static const appStarted = MCode('FAPP001', 'Application started');

  static const authRestoreStarted = MCode(
    'FAUT001',
    'Authentication session restore started',
  );
  static const authRestoreCompleted = MCode(
    'FAUT002',
    'Authentication session restore completed',
  );
  static const authRestoreFailed = MCode(
    'FAUT010',
    'Authentication session restore failed',
  );
  static const authSignInStarted = MCode('FAUT003', 'Sign-in started');
  static const authSignInCompleted = MCode('FAUT004', 'Sign-in completed');
  static const authSignInCancelled = MCode('FAUT005', 'Sign-in cancelled');
  static const authSignInFailed = MCode('FAUT006', 'Sign-in failed');
  static const authRefreshStarted = MCode('FAUT007', 'Token refresh started');
  static const authRefreshCompleted = MCode(
    'FAUT008',
    'Token refresh completed',
  );
  static const authRefreshFailed = MCode('FAUT009', 'Token refresh failed');

  static const apiRequestStarted = MCode('FAPI001', 'API request started');
  static const apiResponseReceived = MCode('FAPI002', 'API response received');
  static const apiRequestFailed = MCode('FAPI003', 'API request failed');

  static const passkeyRegistrationStarted = MCode(
    'FPKY001',
    'Passkey registration started',
  );
  static const passkeyOptionsReceived = MCode(
    'FPKY002',
    'Passkey creation options received',
  );
  static const passkeyProviderCompleted = MCode(
    'FPKY003',
    'Passkey provider ceremony completed',
  );
  static const passkeyRegistrationCompleted = MCode(
    'FPKY004',
    'Passkey registration verified by Gorape',
  );
  static const passkeyRegistrationFailed = MCode(
    'FPKY005',
    'Passkey registration failed',
  );
  static const passkeyProofStarted = MCode('FPKY006', 'Passkey proof started');
  static const passkeyProofCompleted = MCode(
    'FPKY007',
    'Passkey proof verified by Gorape',
  );
  static const passkeyProofFailed = MCode('FPKY008', 'Passkey proof failed');
  static const passkeyAiaStarted = MCode(
    'FAIA001',
    'Keycloak passkey registration action started',
  );
  static const passkeyAiaCompleted = MCode(
    'FAIA002',
    'Keycloak passkey registration action completed',
  );
  static const passkeyAiaFailed = MCode(
    'FAIA003',
    'Keycloak passkey registration action failed',
  );

  static const all = <MCode>[
    appStarted,
    authRestoreStarted,
    authRestoreCompleted,
    authRestoreFailed,
    authSignInStarted,
    authSignInCompleted,
    authSignInCancelled,
    authSignInFailed,
    authRefreshStarted,
    authRefreshCompleted,
    authRefreshFailed,
    apiRequestStarted,
    apiResponseReceived,
    apiRequestFailed,
    passkeyRegistrationStarted,
    passkeyOptionsReceived,
    passkeyProviderCompleted,
    passkeyRegistrationCompleted,
    passkeyRegistrationFailed,
    passkeyProofStarted,
    passkeyProofCompleted,
    passkeyProofFailed,
    passkeyAiaStarted,
    passkeyAiaCompleted,
    passkeyAiaFailed,
  ];

  static final maxCodeLength = all.fold<int>(
    0,
    (length, code) => code.code.length > length ? code.code.length : length,
  );
}
