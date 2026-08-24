import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

import '../../../../../routes/api/v1/auth/logout.dart' as route;
import '../../../../helpers/auth_route_test_utils.dart';
import '../../../../helpers/fake_authentication_service.dart';

void main() {
  late FakeAuthenticationService auth;

  setUp(() {
    auth = FakeAuthenticationService();
  });

  Future<Response> post(
    Object? body, {
    String? contentType = 'application/json',
  }) {
    return route.onRequest(
      authContext(
        auth: auth,
        request: jsonRequest(
          method: 'POST',
          path: '/api/v1/auth/logout',
          body: body,
          contentType: contentType,
        ),
      ),
    );
  }

  group('POST /api/v1/auth/logout', () {
    test('returns 200 for a valid refresh token', () async {
      final response = await post(<String, String>{
        'refresh_token': 'raw-refresh-token',
      });
      final encoded = await response.body();
      final body = jsonDecode(encoded) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);
      expect(data['logged_out'], isTrue);
      expect(auth.logoutCalls, equals(1));
      expect(auth.lastRefreshToken, equals('raw-refresh-token'));
      expect(encoded, isNot(contains('session')));
      expectNoSensitiveAuthLeak(encoded);
    });

    test('returns 200 for unknown tokens without exposing existence', () async {
      final response = await post(<String, String>{
        'refresh_token': 'unknown-refresh-token',
      });
      final encoded = await response.body();
      final body = jsonDecode(encoded) as Map<String, dynamic>;
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);
      expect((body['data'] as Map<String, dynamic>)['logged_out'], isTrue);
      expect(encoded.toLowerCase(), isNot(contains('not found')));
      expect(encoded.toLowerCase(), isNot(contains('unknown')));
    });

    test('returns 400 for malformed input', () async {
      final malformed = await post('{');
      expect(malformed.statusCode, equals(HttpStatus.badRequest));

      final missing = await post(<String, String>{});
      expect(missing.statusCode, equals(HttpStatus.badRequest));
    });

    test('non-POST methods return 405', () async {
      final response = await route.onRequest(
        authContext(
          auth: auth,
          request: jsonRequest(
            method: 'GET',
            path: '/api/v1/auth/logout',
            body: <String, String>{},
          ),
        ),
      );
      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      expect(auth.logoutCalls, equals(0));
    });
  });
}
