import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:test/test.dart';

import '../../../../../routes/api/v1/account/sessions.dart' as route;
import '../../../../helpers/account_route_test_utils.dart';
import '../../../../helpers/auth_route_test_utils.dart';
import '../../../../helpers/fake_current_account_service.dart';

void main() {
  late FakeCurrentAccountService account;

  setUp(() {
    account = FakeCurrentAccountService();
  });

  Future<Response> deleteSessions() {
    return route.onRequest(
      accountContext(
        account: account,
        request: accountRequest(
          method: 'DELETE',
          path: '/api/v1/account/sessions',
        ),
      ),
    );
  }

  group('DELETE /api/v1/account/sessions', () {
    test('revokes all sessions for the authenticated user', () async {
      final response = await deleteSessions();
      final encoded = await response.body();
      final body = jsonDecode(encoded) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);
      expect(data['sessions_revoked'], isTrue);
      expect(account.revokeAllSessionsCalls, equals(1));
      expect(account.lastUserId?.oid, equals('507f1f77bcf86cd799439011'));
      expect(encoded, isNot(contains('refresh_token_hash')));
      expect(encoded, isNot(contains('used_refresh_token_hashes')));
      expectNoSensitiveAuthLeak(encoded);
    });

    test('authentication failure returns 401', () async {
      account.nextError = const InvalidAccessTokenException();
      final response = await deleteSessions();
      final encoded = await response.body();
      final body = jsonDecode(encoded) as Map<String, dynamic>;
      expect(response.statusCode, equals(HttpStatus.unauthorized));
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        equals('invalid_access_token'),
      );
      expectNoSensitiveAuthLeak(encoded);
    });

    test('non-DELETE methods return 405', () async {
      final response = await route.onRequest(
        accountContext(
          account: account,
          request: accountRequest(
            method: 'GET',
            path: '/api/v1/account/sessions',
          ),
        ),
      );
      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      expect(account.revokeAllSessionsCalls, equals(0));
    });
  });
}
