import '../../entity/model/platform.dart';
import '../../entity/request/passkey.dart';
import '../../entity/response/passkey.dart';
import '../repository/passkey.dart';
import '../repository/passkey_device.dart';
import '../repository/platform.dart';
import '../share/error.dart';

abstract interface class PasskeyDeviceUsecase {
  Future<PasskeyRegistrationResult> register({
    required String projectId,
    required String displayName,
  });

  Future<void> provePossession({
    required String projectId,
    required String deviceId,
  });
}

final class PasskeyDeviceUsecaseImpl implements PasskeyDeviceUsecase {
  const PasskeyDeviceUsecaseImpl({
    required PasskeyDeviceRepository devices,
    required PasskeyRepository passkeys,
    required PlatformRepository platforms,
  }) : _devices = devices,
       _passkeys = passkeys,
       _platforms = platforms;

  final PasskeyDeviceRepository _devices;
  final PasskeyRepository _passkeys;
  final PlatformRepository _platforms;

  @override
  Future<PasskeyRegistrationResult> register({
    required String projectId,
    required String displayName,
  }) async {
    final name = displayName.trim();
    if (name.isEmpty) {
      throw const ConfigurationException(
        'デバイス名を入力してください。',
        code: 'display_name_required',
      );
    }
    final platform = _platforms.current();
    _ensurePasskeyPlatform(platform);

    final options = await _devices.createRegistrationOptions(
      projectId,
      platform: platform.wireName,
      displayName: name,
    );
    _ensureLiveChallenge(
      options.challengeId,
      options.isExpired,
      ceremony: 'パスキー登録',
    );
    if (platform == RuntimePlatform.linux) {
      final browser = _requireBrowserPasskeys();
      final browserUrl = options.browserUrl;
      final browserApiOrigin = options.browserApiOrigin;
      if (browserUrl == null ||
          browserUrl.isEmpty ||
          browserApiOrigin == null ||
          browserApiOrigin.isEmpty) {
        throw const ConfigurationException(
          'Gorape Linux passkey portalが設定されていません。',
          code: 'passkey_portal_unconfigured',
        );
      }
      final completion = await browser.registerInBrowser(
        browserUrl: browserUrl,
        browserApiOrigin: browserApiOrigin,
        challengeId: options.challengeId,
      );
      final deviceId = completion['device_id'];
      if (deviceId == null || deviceId.isEmpty) {
        throw const FormatException(
          'Linux browser ceremony returned no device ID.',
        );
      }
      return _devices.registrationResult(projectId, deviceId);
    }
    final credential = await _passkeys.register(options.publicKey);
    return _devices.verifyRegistration(
      projectId,
      PasskeyRegistrationVerifyRequest(
        challengeId: options.challengeId,
        platform: platform.wireName,
        displayName: name,
        credential: credential,
      ),
    );
  }

  @override
  Future<void> provePossession({
    required String projectId,
    required String deviceId,
  }) async {
    final platform = _platforms.current();
    final options = await _devices.createAuthenticationOptions(
      projectId,
      deviceId,
      platform: platform.wireName,
    );
    _ensureLiveChallenge(
      options.challengeId,
      options.isExpired,
      ceremony: '所有証明',
    );
    if (platform == RuntimePlatform.linux) {
      final browser = _requireBrowserPasskeys();
      final browserUrl = options.browserUrl;
      final browserApiOrigin = options.browserApiOrigin;
      if (browserUrl == null ||
          browserUrl.isEmpty ||
          browserApiOrigin == null ||
          browserApiOrigin.isEmpty) {
        throw const ConfigurationException(
          'Gorape Linux passkey portalが設定されていません。',
          code: 'passkey_portal_unconfigured',
        );
      }
      await browser.authenticateInBrowser(
        browserUrl: browserUrl,
        browserApiOrigin: browserApiOrigin,
        challengeId: options.challengeId,
      );
      return;
    }
    final credential = await _passkeys.authenticate(options.publicKey);
    await _devices.verifyAuthentication(
      projectId,
      deviceId,
      PasskeyAuthenticationVerifyRequest(
        challengeId: options.challengeId,
        credential: credential,
      ),
    );
  }

  static void _ensurePasskeyPlatform(RuntimePlatform platform) {
    if (platform == RuntimePlatform.unknown) {
      throw DeviceKeyUnsupportedException(
        'このプラットフォームではパスキー登録に対応していません。',
        platform: platform.wireName,
        guidance: 'Android、iOS、macOS、Windows、Linux、または対応Webブラウザーを使用してください。',
      );
    }
  }

  BrowserPasskeyRepository _requireBrowserPasskeys() {
    final repository = _passkeys;
    if (repository is BrowserPasskeyRepository) return repository;
    throw const DeviceKeyUnsupportedException(
      'Linux browser passkey adapterが利用できません。',
      platform: 'linux',
      guidance: 'アプリのLinux package構成を確認してください。',
    );
  }

  static void _ensureLiveChallenge(
    String id,
    bool expired, {
    required String ceremony,
  }) {
    if (id.isEmpty || expired) {
      throw ChallengeException(
        '$ceremony challengeが無効または期限切れです。もう一度お試しください。',
        code: 'challenge_expired',
      );
    }
  }
}

PasskeyDeviceUsecase newPasskeyDeviceUsecase({
  required PasskeyDeviceRepository devices,
  required PasskeyRepository passkeys,
  required PlatformRepository platforms,
}) => PasskeyDeviceUsecaseImpl(
  devices: devices,
  passkeys: passkeys,
  platforms: platforms,
);
