import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:test/test.dart';

import '../../../../../routes/api/v1/auth/signup.dart' as route;
import '../../../../helpers/auth_route_test_utils.dart';
import '../../../../helpers/fake_authentication_service.dart';

void main() {
  late FakeAuthenticationService auth;

  setUp(() {
    auth = FakeAuthenticationService()..nextSignupResult = fakeSignupResult();
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
          path: '/api/v1/auth/signup',
          body: body,
          contentType: contentType,
        ),
      ),
    );
  }

  group('POST /api/v1/auth/signup', () {
    test('returns 201 pending verification without tokens', () async {
      final response = await post(<String, String>{
        'email': '  Person@example.com  ',
        'password': 'fifteenCharsPass',
        'role': 'customer',
      });
      final encoded = await response.body();
      final body = jsonDecode(encoded) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.created));
      expect(body['success'], isTrue);
      expect(auth.signUpCalls, equals(1));
      expect(auth.lastEmail, equals('Person@example.com'));
      expect(auth.lastPassword, equals('fifteenCharsPass'));
      expect(auth.lastRole, equals(UserRole.customer));
      expect(user['email'], equals('Person@example.com'));
      expect(user['account_status'], equals('active'));
      expect(user['email_verified'], isFalse);
      expect(data['verification_required'], isTrue);
      expect(data.containsKey('tokens'), isFalse);
      expectNoSensitiveAuthLeak(encoded);
    });

    test('returns 201 for a valid cleaner', () async {
      auth.nextSignupResult = fakeSignupResult(role: UserRole.cleaner);
      final response = await post(<String, String>{
        'email': 'cleaner@example.com',
        'password': 'fifteenCharsPass',
        'role': 'cleaner',
      });

      expect(response.statusCode, equals(HttpStatus.created));
      expect(auth.lastRole, equals(UserRole.cleaner));
    });

    test('rejects admin signup with 400', () async {
      final response = await post(<String, String>{
        'email': 'admin@example.com',
        'password': 'fifteenCharsPass',
        'role': 'admin',
      });
      final encoded = await response.body();
      final body = jsonDecode(encoded) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(error['code'], equals('invalid_role'));
      expect(auth.signUpCalls, equals(0));
      expectNoSensitiveAuthLeak(encoded);
    });

    test('returns 400 for malformed JSON', () async {
      final response = await post('{');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        equals('invalid_json'),
      );
      expect(auth.signUpCalls, equals(0));
    });

    test('returns 415 for unsupported media types', () async {
      final response = await post(
        <String, String>{
          'email': 'person@example.com',
          'password': 'fifteenCharsPass',
          'role': 'customer',
        },
        contentType: 'text/plain',
      );
      expect(response.statusCode, equals(HttpStatus.unsupportedMediaType));
      expect(auth.signUpCalls, equals(0));
    });

    test('returns 400 when email is missing or invalid', () async {
      final missing = await post(<String, String>{
        'password': 'fifteenCharsPass',
        'role': 'customer',
      });
      expect(missing.statusCode, equals(HttpStatus.badRequest));

      final invalid = await post(<String, String>{
        'email': 'not-an-email',
        'password': 'fifteenCharsPass',
        'role': 'customer',
      });
      final body = jsonDecode(await invalid.body()) as Map<String, dynamic>;
      expect(invalid.statusCode, equals(HttpStatus.badRequest));
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        equals('invalid_email'),
      );
    });

    test('returns 400 when password is missing', () async {
      final response = await post(<String, String>{
        'email': 'person@example.com',
        'role': 'customer',
      });
      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(auth.signUpCalls, equals(0));
    });

    test('returns 400 when the service rejects a short password', () async {
      auth.nextError = const InvalidAuthInputException(
        code: 'invalid_password',
        message: 'Password does not meet the length requirements.',
      );
      final response = await post(<String, String>{
        'email': 'person@example.com',
        'password': 'too-short',
        'role': 'customer',
      });
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        equals('invalid_password'),
      );
    });

    test('returns 409 for duplicate email', () async {
      auth.nextError = const DuplicateUserEmailException();
      final response = await post(<String, String>{
        'email': 'person@example.com',
        'password': 'fifteenCharsPass',
        'role': 'customer',
      });
      final encoded = await response.body();
      final body = jsonDecode(encoded) as Map<String, dynamic>;
      expect(response.statusCode, equals(HttpStatus.conflict));
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        equals('duplicate_email'),
      );
      expectNoSensitiveAuthLeak(encoded);
    });

    test('returns 503 when authentication is unconfigured', () async {
      auth.nextError = const AuthenticationConfigurationException();
      final response = await post(<String, String>{
        'email': 'person@example.com',
        'password': 'fifteenCharsPass',
        'role': 'customer',
      });
      final encoded = await response.body();
      final body = jsonDecode(encoded) as Map<String, dynamic>;
      expect(response.statusCode, equals(HttpStatus.serviceUnavailable));
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        equals('authentication_unavailable'),
      );
      expectNoSensitiveAuthLeak(encoded);
    });

    test('non-POST methods return 405', () async {
      final response = await route.onRequest(
        authContext(
          auth: auth,
          request: jsonRequest(
            method: 'GET',
            path: '/api/v1/auth/signup',
            body: <String, String>{},
          ),
        ),
      );
      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      expect(auth.signUpCalls, equals(0));
    });
  });
}
