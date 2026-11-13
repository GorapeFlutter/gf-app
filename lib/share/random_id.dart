import 'dart:math';

/// Generates a random identifier without relying on platform plugins.
String randomId([int bytes = 16]) {
  final random = Random.secure();
  final values = List<int>.generate(bytes, (_) => random.nextInt(256));
  final buffer = StringBuffer();
  for (final value in values) {
    buffer.write(value.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}
