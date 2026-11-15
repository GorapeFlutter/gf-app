import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'mcode.dart';

enum AppLogLevel {
  debug(500),
  info(800),
  warning(900),
  error(1000),
  fatal(1200);

  const AppLogLevel(this.value);

  final int value;

  /// GF-01163 — Parses a log-level define with a safe fallback.
  static AppLogLevel parse(String value, {required AppLogLevel fallback}) {
    return switch (value.trim().toUpperCase()) {
      'DEBUG' => AppLogLevel.debug,
      'INFO' => AppLogLevel.info,
      'WARN' || 'WARNING' => AppLogLevel.warning,
      'ERROR' => AppLogLevel.error,
      'FATAL' => AppLogLevel.fatal,
      _ => fallback,
    };
  }
}

class AppLoggerConfig {
  /// GF-01164 — Creates immutable logger configuration.
  const AppLoggerConfig({
    this.component = 'gf-app',
    this.service = 'flutter',
    this.minimumLevel = AppLogLevel.debug,
    this.enabled = true,
    this.structured = true,
    this.includeCaller = false,
  });

  final String component;
  final String service;
  final AppLogLevel minimumLevel;
  final bool enabled;
  final bool structured;
  final bool includeCaller;

  /// GF-01165 — Loads logger controls from compile-time environment defines.
  factory AppLoggerConfig.fromEnvironment() {
    const enableInRelease = bool.fromEnvironment('GF_APP_LOG_ENABLED');
    const levelName = String.fromEnvironment(
      'GF_APP_LOG_LEVEL',
      defaultValue: 'DEBUG',
    );
    const structured = bool.fromEnvironment(
      'GF_APP_LOG_STRUCTURED',
      defaultValue: true,
    );
    const includeCaller = bool.fromEnvironment('GF_APP_LOG_CALLER');

    return AppLoggerConfig(
      minimumLevel: AppLogLevel.parse(
        levelName,
        fallback: kDebugMode ? AppLogLevel.debug : AppLogLevel.info,
      ),
      enabled: kDebugMode || enableInRelease,
      structured: structured,
      includeCaller: includeCaller,
    );
  }
}

typedef AppLogSink = void Function(String message, int level, String name);

/// Structured MCode logger for observing gf-app behavior without logging
/// credentials, WebAuthn payloads, or bearer tokens.
class AppLogger {
  /// GF-01166 — Creates an MCode logger with an injectable output sink.
  AppLogger({AppLoggerConfig? config, AppLogSink? sink})
    : config = config ?? AppLoggerConfig.fromEnvironment(),
      _sink = sink ?? _developerSink;

  static final instance = AppLogger();

  static final _sensitiveKey = RegExp(
    r'(access.?token|refresh.?token|id.?token|authorization|secret|password|credential|challenge|signature|attestation|private.?key|public.?key|client.?data|authenticator.?data|user.?handle|user.?id|display.?name|raw.?id|assertion|proof|webauthn|response|cookie|email|request.?body)',
    caseSensitive: false,
  );
  static final _bearer = RegExp(
    r'Bearer\s+[A-Za-z0-9._~+/-]+=*',
    caseSensitive: false,
  );
  static final _jwt = RegExp(
    r'\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b',
  );
  static final _querySecret = RegExp(
    r'((?:access_token|refresh_token|id_token|client_secret|password)=)[^&\s]+',
    caseSensitive: false,
  );
  static final _privateKey = RegExp(
    r'-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----',
  );
  static final _uuid = RegExp(
    r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
  );

  final AppLoggerConfig config;
  final AppLogSink _sink;

  /// GF-01167 — Emits a debug MCode record.
  void debug(MCode code, {Map<String, Object?> fields = const {}}) =>
      _write(AppLogLevel.debug, code, fields: fields);

  /// GF-01168 — Emits an info MCode record.
  void info(MCode code, {Map<String, Object?> fields = const {}}) =>
      _write(AppLogLevel.info, code, fields: fields);

  /// GF-01169 — Emits a warning MCode record without serializing the error.
  void warning(
    MCode code, {
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  }) => _write(
    AppLogLevel.warning,
    code,
    fields: fields,
    error: error,
    stackTrace: stackTrace,
  );

  /// GF-01170 — Emits an error MCode record without serializing the error.
  void error(
    MCode code, {
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  }) => _write(
    AppLogLevel.error,
    code,
    fields: fields,
    error: error,
    stackTrace: stackTrace,
  );

  /// Logs a fatal condition. The mobile process is not terminated.
  /// GF-01171 — Emits a fatal MCode record without terminating the process.
  void fatal(
    MCode code, {
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  }) => _write(
    AppLogLevel.fatal,
    code,
    fields: fields,
    error: error,
    stackTrace: stackTrace,
  );

  /// GF-01172 — Redacts dynamic identifiers from an API path.
  static String redactPath(String path) {
    final segments = path.split('/');
    for (var index = 0; index + 1 < segments.length; index++) {
      final segment = segments[index].toLowerCase();
      final next = segments[index + 1];
      final isStaticRoute = switch (segment) {
        'devices' => const {'registration', 'passkeys'}.contains(next),
        'groups' => next == 'roles',
        _ => false,
      };
      if (!isStaticRoute &&
          const {'projects', 'devices', 'groups', 'roles'}.contains(segment) &&
          next.isNotEmpty) {
        segments[index + 1] = '{id}';
      }
    }
    return segments.join('/').replaceAll(_uuid, '{id}');
  }

  /// GF-01173 — Filters, redacts, formats, and emits one logger record.
  void _write(
    AppLogLevel level,
    MCode code, {
    required Map<String, Object?> fields,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!config.enabled || level.index < config.minimumLevel.index) return;

    final safeFields = _sanitizeFields(fields);
    if (error != null) safeFields['error_type'] = error.runtimeType.toString();
    if (config.includeCaller && stackTrace != null) {
      safeFields['stack_trace'] = stackTrace.toString();
    }
    if (config.includeCaller) {
      final frames = StackTrace.current.toString().split('\n');
      if (frames.length > 2) safeFields['caller'] = frames[2].trim();
    }

    final entry = <String, Object?>{
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'level': level.name.toUpperCase().padRight(7),
      'code': code.padded(AppMCodes.maxCodeLength),
      'component': config.component,
      'service': config.service,
      'message': code.message,
      if (safeFields.isNotEmpty) 'fields': safeFields,
    };
    final message = config.structured
        ? jsonEncode(entry)
        : '[${entry['timestamp']}] [${entry['level']}] [${config.component}] '
              '[${entry['code']}] ${entry['message']}'
              '${safeFields.isEmpty ? '' : ' ${jsonEncode(safeFields)}'}';
    _sink(message, level.value, config.service);
  }

  /// GF-01174 — Redacts sensitive fields at the top level.
  static Map<String, Object?> _sanitizeFields(Map<String, Object?> fields) {
    final result = <String, Object?>{};
    for (final entry in fields.entries) {
      result[entry.key] = _sensitiveKey.hasMatch(entry.key)
          ? '[REDACTED]'
          : _sanitizeValue(entry.value);
    }
    return result;
  }

  /// GF-01175 — Recursively sanitizes structured values with a depth limit.
  static Object? _sanitizeValue(Object? value, {int depth = 0}) {
    if (depth > 5) return '[MAX_DEPTH]';
    if (value == null || value is bool || value is num) return value;
    if (value is String) return _sanitizeString(value);
    if (value is Map) {
      final safe = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key.toString();
        safe[key] = _sensitiveKey.hasMatch(key)
            ? '[REDACTED]'
            : _sanitizeValue(entry.value, depth: depth + 1);
      }
      return safe;
    }
    if (value is Iterable) {
      return value
          .map((item) => _sanitizeValue(item, depth: depth + 1))
          .toList();
    }
    return value.runtimeType.toString();
  }

  /// GF-01176 — Redacts credential-shaped text, JWTs, and private keys.
  static String _sanitizeString(String value) {
    return value
        .replaceAll(_privateKey, '[REDACTED PRIVATE KEY]')
        .replaceAll(_bearer, 'Bearer [REDACTED]')
        .replaceAll(_jwt, '[REDACTED JWT]')
        .replaceAllMapped(
          _querySecret,
          (match) => '${match.group(1)}[REDACTED]',
        );
  }

  /// GF-01177 — Sends sanitized records to dart:developer.
  static void _developerSink(String message, int level, String name) {
    developer.log(message, name: name, level: level);
  }
}
