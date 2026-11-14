import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'share/error.dart';

/// GF-00402 — Starts the Flutter application.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(retry: _retryPolicy, child: GorapeApp()));
}

/// GF-00403 — Handles retry policy in top level.
/// Riverpod retries failed provider builds with backoff by default.
///
/// Authorization and validation failures are terminal: retrying only delays
/// the error UI. Transport failures and 5xx responses are worth retrying.
Duration? _retryPolicy(int retryCount, Object error) {
  if (_isPermanent(error)) return null;
  if (retryCount >= 3) return null;
  return Duration(milliseconds: 400 * (1 << retryCount));
}

/// GF-00404 — Handles is permanent in top level.
bool _isPermanent(Object error) {
  if (error is AuthException ||
      error is ConfigurationException ||
      error is FormatException) {
    return true;
  }
  if (error is ApiException) {
    return error.statusCode >= 400 && error.statusCode < 500;
  }
  return false;
}
