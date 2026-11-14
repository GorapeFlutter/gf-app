import 'package:http/http.dart' as http;

import 'http_client_stub.dart'
    if (dart.library.io) 'http_client_io.dart'
    as platform;

/// Creates the default client, adding the local development CA only when the
/// Android/debug runner explicitly supplies it through a dart-define.
http.Client newDefaultHttpClient() => platform.newDefaultHttpClient();
