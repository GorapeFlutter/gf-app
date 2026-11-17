import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  // GF-01418 — Attach the Flutter view and install native key channels after nib loading.
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    SecureNativeKeyChannels.install(binaryMessenger: flutterViewController.engine.binaryMessenger)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
