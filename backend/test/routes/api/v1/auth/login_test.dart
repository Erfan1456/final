import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:test/test.dart';

import '../../../../../routes/api/v1/auth/login.dart' as route;
import '../../../../helpers/auth_route_test_utils.dart';
import '../../../../helpers/fake_authentication_service.dart';

void main() {
  late FakeAuthenticationService auth;

  setUp(() {
    auth = FakeAuthenticationService()..nextAuthResult = fakeAuthResult();
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
          path: '/api/v1/auth/login',
          body: body,
          contentType: contentType,
        ),
      ),
    );
  }

  group('POST /api/v1/auth/login', () {
    test('returns 200 for valid credentials', () async {
      final response = await post(<String, String>{
        'email': '  Person@example.com  ',
        'password': 'correct-password',
      });
      final encoded = await response.body();
      final body = jsonDecode(encoded) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);
      expect(auth.loginCalls, equals(1));
      expect(auth.lastEmail, equals('Person@example.com'));
      expect(auth.lastPassword, equals('correct-password'));
      expect(tokens.containsKey('access_token'), isTrue);
      expect(tokens.containsKey('refresh_token'), isTrue);
      expect(tokens['token_type'], equals('Bearer'));
      expect(tokens['expires_in'], equals(900));
      expectNoSensitiveAuthLeak(encoded);
    });

    test(
      'returns the same 401 body for wrong credentials and unknown users',
      () async {
        auth.nextError = const InvalidCredentialsException();
        final wrong = await post(<String, String>{
          'email': 'person@example.com',
          'password': 'wrong-password',
        });
        final unknown = await post(<String, String>{
          'email': 'missing@example.com',
          'password': 'wrong-password',
        });
        final wrongBody = await wrong.body();
        final unknownBody = await unknown.body();

        expect(wrong.statusCode, equals(HttpStatus.unauthorized));
        expect(unknown.statusCode, equals(HttpStatus.unauthorized));
        expect(wrongBody, equals(unknownBody));
        final error = jsonDecode(wrongBody) as Map<String, dynamic>;
        expect(
          (error['error'] as Map<String, dynamic>)['code'],
          equals('invalid_credentials'),
        );
        expect(
          (error['error'] as Map<String, dynamic>)['message'],
          equals('Invalid email or password.'),
        );
        expect(wrongBody, isNot(contains('not found')));
        expect(wrongBody, isNot(contains('does not exist')));
        expectNoSensitiveAuthLeak(wrongBody);
      },
    );

    test('returns 403 for an inactive account', () async {
      auth.nextError = const AccountUnavailableException();
      final response = await post(<String, String>{
        'email': 'person@example.com',
        'password': 'correct-password',
      });
      final encoded = await response.body();
      final body = jsonDecode(encoded) as Map<String, dynamic>;
      expect(response.statusCode, equals(HttpStatus.forbidden));
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        equals('account_unavailable'),
      );
      expectNoSensitiveAuthLeak(encoded);
    });

    test('returns 400 for malformed JSON and missing fields', () async {
      final malformed = await post('{');
      expect(malformed.statusCode, equals(HttpStatus.badRequest));

      final missing = await post(<String, String>{
        'email': 'person@example.com',
      });
      expect(missing.statusCode, equals(HttpStatus.badRequest));
    });

    test('returns 503 when authentication is unconfigured', () async {
      auth.nextError = const AuthenticationConfigurationException();
      final response = await post(<String, String>{
        'email': 'person@example.com',
        'password': 'correct-password',
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
            path: '/api/v1/auth/login',
            body: <String, String>{},
          ),
        ),
      );
      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      expect(auth.loginCalls, equals(0));
    });
  });
}
