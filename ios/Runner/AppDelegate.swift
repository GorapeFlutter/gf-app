import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  // GF-01415 — Register Flutter plugins and the Apple native-key channel at launch.
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      SecureNativeKeyChannels.install(binaryMessenger: controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
