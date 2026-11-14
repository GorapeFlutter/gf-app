import 'dart:math';

/// GF-00666 — Handles random id in top level.
/// Generates a random identifier without relying on platform plugins.
String randomId([int bytes = 16]) {
  final random = Random.secure();
  final values = List<int>.generate(
    bytes,
    /* GF-00667 — Runs an inline callback in top level.randomId. */ (_) =>
        random.nextInt(256),
  );
  final buffer = StringBuffer();
  for (final value in values) {
    buffer.write(value.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}
