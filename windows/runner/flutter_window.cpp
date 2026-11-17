#include "flutter_window.h"

#include <optional>
#include <string>
#include <vector>

#include "flutter/generated_plugin_registrant.h"
#include "windows_native_keys.h"

// GF-01471 — Initialize a Flutter host window with its Dart project.
FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

// GF-01472 — Release the Flutter host window.
FlutterWindow::~FlutterWindow() {}

// GF-01473 — Create the Flutter controller and register Windows native-key channels.
bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  RegisterWindowsNativeKeyChannels(flutter_controller_->engine()->messenger(),
                                   &device_key_channel_);
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback(/* GF-01476 — Show the window after Flutter renders its first frame. */ [&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

// GF-01474 — Release the Flutter controller before destroying the window.
void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
// GF-01475 — Give Flutter first opportunity to process top-level Win32 messages.
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
