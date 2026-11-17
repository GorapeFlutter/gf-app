import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // GF-01416 — Terminate the app after its last window closes.
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  // GF-01417 — Allow secure state restoration for the macOS app.
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
