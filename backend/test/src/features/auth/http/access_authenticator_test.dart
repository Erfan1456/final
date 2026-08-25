import 'dart:convert';

import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_composition.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/access_authenticator.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/jwt_access_token_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

void main() {
  const fakeSecret = 'test-access-token-secret-32bytes';
  final userId = ObjectId.fromHexString('507f1f77bcf86cd799439011');
  final sessionId = ObjectId.fromHexString('507f1f77bcf86cd799439012');
  final tokens = JwtAccessTokenService(secret: fakeSecret);
  final authenticator = AccessAuthenticator(tokens: tokens);

  String issueToken() {
    return tokens.issue(
      userId: userId,
      sessionId: sessionId,
      role: UserRole.cleaner,
    );
  }

  group('AccessAuthenticator', () {
    test('extracts a Bearer token and returns a principal', () {
      final token = issueToken();
      final principal = authenticator.authenticate('Bearer $token');

      expect(principal.userId, equals(userId));
      expect(principal.sessionId, equals(sessionId));
      expect(principal.role, equals(UserRole.cleaner));
      expect(principal.jwtId, isNotEmpty);
      expect(principal.toString(), isNot(contains(token)));
    });

    test('accepts a case-insensitive Bearer scheme', () {
      final token = issueToken();
      final principal = authenticator.authenticate('bearer $token');
      expect(principal.userId, equals(userId));
    });

    test('missing Authorization throws InvalidAccessTokenException', () {
      expect(
        () => authenticator.authenticate(null),
        throwsA(isA<InvalidAccessTokenException>()),
      );
      expect(
        () => authenticator.authenticate(''),
        throwsA(isA<InvalidAccessTokenException>()),
      );
    });

    test('wrong scheme throws InvalidAccessTokenException', () {
      expect(
        () => authenticator.authenticate('Basic abc'),
        throwsA(isA<InvalidAccessTokenException>()),
      );
      expect(
        () => authenticator.authenticate('Token abc'),
        throwsA(isA<InvalidAccessTokenException>()),
      );
    });

    test('blank Bearer token throws InvalidAccessTokenException', () {
      expect(
        () => authenticator.authenticate('Bearer'),
        throwsA(isA<InvalidAccessTokenException>()),
      );
      expect(
        () => authenticator.authenticate('Bearer '),
        throwsA(isA<InvalidAccessTokenException>()),
      );
    });

    test('invalid access token throws InvalidAccessTokenException', () {
      expect(
        () => authenticator.authenticate('Bearer not-a-valid-jwt'),
        throwsA(isA<InvalidAccessTokenException>()),
      );
    });

    test(
      'unavailable token configuration throws configuration exception',
      () {
        const unavailable = AccessAuthenticator(
          tokens: UnavailableAccessTokenService(),
        );
        expect(
          () => unavailable.authenticate('Bearer fake-token'),
          throwsA(isA<AccessTokenConfigurationException>()),
        );
      },
    );

    test(
      'does not treat JWT payload JSON as the principal source of email',
      () {
        final token = issueToken();
        final principal = authenticator.authenticate('Bearer $token');
        final encoded = jsonEncode(principal.toString());
        expect(encoded, isNot(contains('password')));
        expect(encoded, isNot(contains('email')));
        expect(encoded, isNot(contains('refresh')));
      },
    );
  });
}
