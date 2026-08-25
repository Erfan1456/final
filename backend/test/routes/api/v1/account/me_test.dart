import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:test/test.dart';

import '../../../../../routes/api/v1/account/me.dart' as route;
import '../../../../helpers/account_route_test_utils.dart';
import '../../../../helpers/auth_route_test_utils.dart';
import '../../../../helpers/fake_current_account_service.dart';

void main() {
  late FakeCurrentAccountService account;

  setUp(() {
    account = FakeCurrentAccountService()..nextUser = fakeAuthResult().user;
  });

  Future<Response> getMe() {
    return route.onRequest(
      accountContext(
        account: account,
        request: accountRequest(
          method: 'GET',
          path: '/api/v1/account/me',
        ),
      ),
    );
  }

  group('GET /api/v1/account/me', () {
    test(
      'returns 200 with the safe public account for an active user',
      () async {
        final response = await getMe();
        final encoded = await response.body();
        final body = jsonDecode(encoded) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>;

        expect(response.statusCode, equals(HttpStatus.ok));
        expect(body['success'], isTrue);
        expect(account.getCurrentUserCalls, equals(1));
        expect(account.lastUserId?.oid, equals('507f1f77bcf86cd799439011'));
        expect(user['id'], equals('507f1f77bcf86cd799439011'));
        expect(user['role'], equals('customer'));
        expect(user['email'], equals('Person@example.com'));
        expect(user['account_status'], equals('active'));
        expect(user['email_verified'], isFalse);
        expect(user.containsKey('created_at'), isTrue);
        expect(user.containsKey('updated_at'), isTrue);
        expect(encoded, isNot(contains('password_hash')));
        expect(encoded, isNot(contains('passwordHash')));
        expect(encoded, isNot(contains('email_normalized')));
        expect(encoded, isNot(contains('hashed-password-must-not-appear')));
        expectNoSensitiveAuthLeak(encoded);
      },
    );

    test('returns the persisted role from UserAccount', () async {
      account.nextUser = fakeAuthResult(role: UserRole.cleaner).user;
      final response = await getMe();
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final user =
          (body['data'] as Map<String, dynamic>)['user']
              as Map<String, dynamic>;
      expect(user['role'], equals('cleaner'));
    });

    test('missing user returns generic authentication failure', () async {
      account.nextError = const InvalidAccessTokenException();
      final response = await getMe();
      final encoded = await response.body();
      final body = jsonDecode(encoded) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.unauthorized));
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        equals('invalid_access_token'),
      );
      expect(
        (body['error'] as Map<String, dynamic>)['message'],
        equals('Authentication is required.'),
      );
      expect(encoded, isNot(contains('not found')));
      expectNoSensitiveAuthLeak(encoded);
    });

    test('suspended account returns 403 account_unavailable', () async {
      account.nextError = const AccountUnavailableException();
      final response = await getMe();
      final encoded = await response.body();
      final body = jsonDecode(encoded) as Map<String, dynamic>;
      expect(response.statusCode, equals(HttpStatus.forbidden));
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        equals('account_unavailable'),
      );
      expectNoSensitiveAuthLeak(encoded);
    });

    test('deactivated account returns 403 account_unavailable', () async {
      account
        ..nextUser = fakeAuthResult().user
        ..nextError = const AccountUnavailableException();
      final response = await getMe();
      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    test('non-GET methods return 405', () async {
      final response = await route.onRequest(
        accountContext(
          account: account,
          request: accountRequest(
            method: 'POST',
            path: '/api/v1/account/me',
          ),
        ),
      );
      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      expect(account.getCurrentUserCalls, equals(0));
    });
  });

  test('suspended and deactivated share the same 403 body', () async {
    account.nextError = const AccountUnavailableException();
    final suspended = await getMe();
    final deactivated = await getMe();
    expect(await suspended.body(), equals(await deactivated.body()));
  });
}
