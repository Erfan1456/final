import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session_exceptions.dart';
import 'package:test/test.dart';

import '../../../../../routes/api/v1/auth/refresh.dart' as route;
import '../../../../helpers/auth_route_test_utils.dart';
import '../../../../helpers/fake_authentication_service.dart';

void main() {
  late FakeAuthenticationService auth;

  setUp(() {
    auth = FakeAuthenticationService()
      ..nextRefreshResult = fakeRefreshedTokens();
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
          path: '/api/v1/auth/refresh',
          body: body,
          contentType: contentType,
        ),
      ),
    );
  }

  group('POST /api/v1/auth/refresh', () {
    test('returns 200 with new access and refresh tokens', () async {
      final response = await post(<String, String>{
        'refresh_token': 'previous-refresh-token',
      });
      final encoded = await response.body();
      final body = jsonDecode(encoded) as Map<String, dynamic>;
      final tokens =
          (body['data'] as Map<String, dynamic>)['tokens']
              as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);
      expect(auth.refreshCalls, equals(1));
      expect(auth.lastRefreshToken, equals('previous-refresh-token'));
      expect(tokens.containsKey('access_token'), isTrue);
      expect(tokens.containsKey('refresh_token'), isTrue);
      expect(tokens['token_type'], equals('Bearer'));
      expect(tokens['expires_in'], equals(900));
      expect(body.containsKey('user'), isFalse);
      expectNoSensitiveAuthLeak(encoded);
    });

    test('returns generic 401 for invalid tokens', () async {
      auth.nextError = const InvalidRefreshCredentialsException();
      final response = await post(<String, String>{
        'refresh_token': 'unknown-refresh-token',
      });
      final encoded = await response.body();
      final body = jsonDecode(encoded) as Map<String, dynamic>;
      expect(response.statusCode, equals(HttpStatus.unauthorized));
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        equals('invalid_refresh_token'),
      );
      expect(encoded.toLowerCase(), isNot(contains('replay')));
      expectNoSensitiveAuthLeak(encoded);
    });

    test('maps replay-internal exceptions to generic 401', () async {
      auth.nextError = const RefreshTokenReuseDetectedException();
      final response = await post(<String, String>{
        'refresh_token': 'consumed-refresh-token',
      });
      final encoded = await response.body();
      final body = jsonDecode(encoded) as Map<String, dynamic>;
      expect(response.statusCode, equals(HttpStatus.unauthorized));
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        equals('invalid_refresh_token'),
      );
      expect(encoded.toLowerCase(), isNot(contains('replay')));
      expect(encoded, isNot(contains('RefreshTokenReuseDetectedException')));
    });

    test('returns 400 for malformed JSON and missing refresh_token', () async {
      final malformed = await post('{');
      expect(malformed.statusCode, equals(HttpStatus.badRequest));

      final missing = await post(<String, String>{});
      expect(missing.statusCode, equals(HttpStatus.badRequest));
    });

    test('returns 503 when authentication is unconfigured', () async {
      auth.nextError = const AuthenticationConfigurationException();
      final response = await post(<String, String>{
        'refresh_token': 'previous-refresh-token',
      });
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(response.statusCode, equals(HttpStatus.serviceUnavailable));
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        equals('authentication_unavailable'),
      );
    });

    test('non-POST methods return 405', () async {
      final response = await route.onRequest(
        authContext(
          auth: auth,
          request: jsonRequest(
            method: 'GET',
            path: '/api/v1/auth/refresh',
            body: <String, String>{},
          ),
        ),
      );
      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      expect(auth.refreshCalls, equals(0));
    });
  });
}
