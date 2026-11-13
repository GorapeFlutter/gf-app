import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gf_app/api/gorape_api_client.dart';
import 'package:gf_app/api/models/registration.dart';
import 'package:gf_app/core/errors/app_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late List<http.Request> requests;

  GorapeApiClient clientWith(
    Future<http.Response> Function(http.Request request) handler, {
    String? accessToken = 'access-token',
  }) {
    requests = [];
    return GorapeApiClient(
      baseUrl: 'http://localhost:8000/',
      httpClient: MockClient((request) {
        requests.add(request);
        return handler(request);
      }),
      accessTokenProvider: () => accessToken,
    );
  }

  group('GorapeApiClient', () {
    test('lists projects with the access token (never an ID token)', () async {
      final api = clientWith(
        (_) async => http.Response(
          jsonEncode([
            {
              'id': 'project-1',
              'slug': 'gorape',
              'name': 'Gorape',
              'oidc_issuer': 'http://localhost:8080/realms/gorape',
              'keycloak_realm': 'gorape',
              'status': 'active',
            },
          ]),
          200,
        ),
      );

      final projects = await api.listProjects();

      expect(projects, hasLength(1));
      expect(projects.single.slug, 'gorape');
      expect(requests.single.method, 'GET');
      expect(
        requests.single.url.toString(),
        'http://localhost:8000/v1/projects',
      );
      expect(requests.single.headers['Authorization'], 'Bearer access-token');
      expect(requests.single.headers.containsKey('Content-Type'), isFalse);
    });

    test('uses unauthenticated health endpoint', () async {
      final api = clientWith(
        (_) async => http.Response('{"service":"gorape","status":"ok"}', 200),
        accessToken: null,
      );

      final health = await api.health();

      expect(health['status'], 'ok');
      expect(requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test(
      'submits registration evidence using the OpenAPI field names',
      () async {
        final api = clientWith(
          (_) async => http.Response(
            jsonEncode({
              'id': 'device-1',
              'project_id': 'project-1',
              'owner_principal_id': 'principal-1',
              'platform': 'android',
              'display_name': 'Pixel',
              'status': 'active',
              'registered_at': '2026-01-01T00:00:00Z',
              'version': 1,
            }),
            201,
          ),
        );

        final device = await api.verifyRegistration(
          'project-1',
          const RegistrationVerifyRequest(
            challengeId: 'challenge-1',
            platform: 'android',
            displayName: 'Pixel',
            publicKeyPem: '-----BEGIN PUBLIC KEY-----',
            keyIdentifier: 'key-1',
            algorithm: 'ES256',
            evidence: {
              'certificate_chain': ['leaf', 'intermediate', 'root'],
            },
          ),
        );

        expect(device.id, 'device-1');
        final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
        expect(
          requests.single.url.path,
          '/v1/projects/project-1/devices/registration/verify',
        );
        expect(body['challenge_id'], 'challenge-1');
        expect(body['public_key_pem'], '-----BEGIN PUBLIC KEY-----');
        expect(body['evidence']['certificate_chain'].first, 'leaf');
      },
    );

    test('submits a Base64url proof signature', () async {
      final api = clientWith(
        (_) async => http.Response('{"status":"verified"}', 200),
      );

      await api.verifyProof(
        'project-1',
        'device-1',
        const ProofVerifyRequest(
          challengeId: 'challenge-1',
          signature: 'c2lnbmF0dXJl',
        ),
      );

      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(
        requests.single.url.path,
        '/v1/projects/project-1/devices/device-1/verify',
      );
      expect(body, {
        'challenge_id': 'challenge-1',
        'signature': 'c2lnbmF0dXJl',
      });
    });

    test('maps 401 to AuthException with guidance', () async {
      final api = clientWith(
        (_) async => http.Response(
          '{"code":"unauthorized","message":"invalid token"}',
          401,
        ),
      );

      await expectLater(
        api.listProjects(),
        throwsA(
          isA<AuthException>()
              .having((error) => error.code, 'code', 'unauthorized')
              .having((error) => error.guidance, 'guidance', isNotNull),
        ),
      );
    });

    test('refreshes the access token once and retries after a 401', () async {
      var token = 'expired-token';
      var refreshes = 0;
      final refreshedRequests = <http.Request>[];
      final api = GorapeApiClient(
        baseUrl: 'http://localhost:8000',
        httpClient: MockClient((request) async {
          refreshedRequests.add(request);
          if (refreshedRequests.length == 1) {
            return http.Response('{"code":"expired"}', 401);
          }
          return http.Response('[]', 200);
        }),
        accessTokenProvider: () => token,
        refreshAccessToken: () async {
          refreshes += 1;
          token = 'fresh-token';
          return true;
        },
      );

      final projects = await api.listProjects();

      expect(projects, isEmpty);
      expect(refreshes, 1);
      expect(refreshedRequests, hasLength(2));
      expect(
        refreshedRequests[0].headers['Authorization'],
        'Bearer expired-token',
      );
      expect(
        refreshedRequests[1].headers['Authorization'],
        'Bearer fresh-token',
      );
    });

    test('does not retry when the token refresh fails', () async {
      var refreshes = 0;
      final refreshedRequests = <http.Request>[];
      final api = GorapeApiClient(
        baseUrl: 'http://localhost:8000',
        httpClient: MockClient((request) async {
          refreshedRequests.add(request);
          return http.Response(
            '{"code":"unauthorized","message":"invalid token"}',
            401,
          );
        }),
        accessTokenProvider: () => 'expired-token',
        refreshAccessToken: () async {
          refreshes += 1;
          return false;
        },
      );

      await expectLater(api.listProjects(), throwsA(isA<AuthException>()));
      expect(refreshes, 1);
      expect(refreshedRequests, hasLength(1));
    });

    test('maps 422 to an ApiException explaining attestation', () async {
      final api = clientWith(
        (_) async => http.Response(
          '{"code":"attestation_failed","message":"chain invalid"}',
          422,
        ),
      );

      await expectLater(
        api.listDevices('project-1'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having(
                (error) => error.guidance,
                'guidance',
                contains('信頼アンカー'),
              ),
        ),
      );
    });

    test('fails before calling the network without an access token', () async {
      final api = clientWith(
        (_) async => http.Response('[]', 200),
        accessToken: null,
      );

      await expectLater(
        api.listProjects(),
        throwsA(
          isA<AuthException>().having(
            (error) => error.code,
            'code',
            'missing_access_token',
          ),
        ),
      );
      expect(requests, isEmpty);
    });

    test('rejects malformed JSON arrays', () async {
      final api = clientWith(
        (_) async => http.Response('{"not":"an array"}', 200),
      );

      await expectLater(api.listProjects(), throwsFormatException);
    });
  });
}
