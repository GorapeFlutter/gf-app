import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client newDefaultHttpClient() {
  const encodedLocalCA = String.fromEnvironment('GORAPE_TLS_CA_CERT_BASE64');
  if (!kDebugMode || encodedLocalCA.isEmpty) return http.Client();

  final context = SecurityContext(withTrustedRoots: true)
    ..setTrustedCertificatesBytes(base64.decode(encodedLocalCA));
  return IOClient(HttpClient(context: context));
}
