import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_claims.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/jwt_access_token_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

void main() {
  const fakeSecret = 'test-access-token-secret-32bytes';
  const otherSecret = 'other-access-token-secret-32byte';
  final userId = ObjectId.fromHexString('507f1f77bcf86cd799439011');
  final sessionId = ObjectId.fromHexString('507f1f77bcf86cd799439012');

  Map<String, dynamic> headerOf(String token) {
    final part = token.split('.')[0];
    var padded = part;
    final remainder = padded.length % 4;
    if (remainder != 0) {
      padded = padded.padRight(padded.length + (4 - remainder), '=');
    }
    return jsonDecode(utf8.decode(base64Url.decode(padded)))
        as Map<String, dynamic>;
  }

  JWT verified(String token, {String secret = fakeSecret}) {
    return JWT.verify(
      token,
      SecretKey(secret),
      issuer: accessTokenIssuer,
      audience: Audience.one(accessTokenAudience),
    );
  }

  group('JwtAccessTokenService', () {
    final service = JwtAccessTokenService(secret: fakeSecret);

    test('issues and verifies claims with a 15-minute HS256 token', () {
      final token = service.issue(
        userId: userId,
        sessionId: sessionId,
        role: UserRole.cleaner,
      );
      final claims = service.verify(token);
      final jwt = verified(token);

      expect(claims.userId, equals(userId));
      expect(claims.sessionId, equals(sessionId));
      expect(claims.role, equals(UserRole.cleaner));
      expect(claims.jwtId, isNotEmpty);
      expect(
        claims.expiresAt.difference(claims.issuedAt).inSeconds,
        inInclusiveRange(14 * 60, 16 * 60),
      );
      expect(jwt.issuer, equals(accessTokenIssuer));
      expect(jwt.audience?.first, equals(accessTokenAudience));
      expect(headerOf(token)['alg'], equals('HS256'));
      expect(jwt.header?['alg'], equals('HS256'));
    });

    test('issues unique jti values', () {
      final first = service.verify(
        service.issue(
          userId: userId,
          sessionId: sessionId,
          role: UserRole.customer,
        ),
      );
      final second = service.verify(
        service.issue(
          userId: userId,
          sessionId: sessionId,
          role: UserRole.customer,
        ),
      );

      expect(first.jwtId, isNot(equals(second.jwtId)));
    });

    test('rejects a token signed with a different secret', () {
      final token = service.issue(
        userId: userId,
        sessionId: sessionId,
        role: UserRole.customer,
      );
      final other = JwtAccessTokenService(secret: otherSecret);

      expect(
        () => other.verify(token),
        throwsA(isA<InvalidAccessTokenException>()),
      );
    });

    test('rejects an expired token', () {
      final token =
          JWT(
            <String, dynamic>{
              'sid': sessionId.oid,
              'role': UserRole.customer.wireValue,
            },
            subject: userId.oid,
            issuer: accessTokenIssuer,
            audience: Audience.one(accessTokenAudience),
            jwtId: 'fake-expired-jti-value1',
          ).sign(
            SecretKey(fakeSecret),
            expiresIn: const Duration(seconds: -1),
          );

      expect(
        () => service.verify(token),
        throwsA(isA<InvalidAccessTokenException>()),
      );
    });

    test('rejects the wrong issuer', () {
      final token =
          JWT(
            <String, dynamic>{
              'sid': sessionId.oid,
              'role': UserRole.customer.wireValue,
            },
            subject: userId.oid,
            issuer: 'other-issuer',
            audience: Audience.one(accessTokenAudience),
            jwtId: 'fake-wrong-issuer-jti01',
          ).sign(
            SecretKey(fakeSecret),
            expiresIn: accessTokenLifetime,
          );

      expect(
        () => service.verify(token),
        throwsA(isA<InvalidAccessTokenException>()),
      );
    });

    test('rejects the wrong audience', () {
      final token =
          JWT(
            <String, dynamic>{
              'sid': sessionId.oid,
              'role': UserRole.customer.wireValue,
            },
            subject: userId.oid,
            issuer: accessTokenIssuer,
            audience: Audience.one('other-audience'),
            jwtId: 'fake-wrong-audience-jti1',
          ).sign(
            SecretKey(fakeSecret),
            expiresIn: accessTokenLifetime,
          );

      expect(
        () => service.verify(token),
        throwsA(isA<InvalidAccessTokenException>()),
      );
    });

    test('rejects a malformed token', () {
      expect(
        () => service.verify('not-a-jwt'),
        throwsA(isA<InvalidAccessTokenException>()),
      );
    });

    test('rejects a token missing a required claim', () {
      final token =
          JWT(
            <String, dynamic>{
              'role': UserRole.customer.wireValue,
            },
            subject: userId.oid,
            issuer: accessTokenIssuer,
            audience: Audience.one(accessTokenAudience),
            jwtId: 'fake-missing-sid-jti0001',
          ).sign(
            SecretKey(fakeSecret),
            expiresIn: accessTokenLifetime,
          );

      expect(
        () => service.verify(token),
        throwsA(isA<InvalidAccessTokenException>()),
      );
    });

    test('rejects a malformed user ObjectId', () {
      final token =
          JWT(
            <String, dynamic>{
              'sid': sessionId.oid,
              'role': UserRole.customer.wireValue,
            },
            subject: 'not-an-object-id',
            issuer: accessTokenIssuer,
            audience: Audience.one(accessTokenAudience),
            jwtId: 'fake-bad-user-id-jti0001',
          ).sign(
            SecretKey(fakeSecret),
            expiresIn: accessTokenLifetime,
          );

      expect(
        () => service.verify(token),
        throwsA(isA<InvalidAccessTokenException>()),
      );
    });

    test('rejects a malformed session ObjectId', () {
      final token =
          JWT(
            <String, dynamic>{
              'sid': 'not-an-object-id',
              'role': UserRole.customer.wireValue,
            },
            subject: userId.oid,
            issuer: accessTokenIssuer,
            audience: Audience.one(accessTokenAudience),
            jwtId: 'fake-bad-session-id-jti01',
          ).sign(
            SecretKey(fakeSecret),
            expiresIn: accessTokenLifetime,
          );

      expect(
        () => service.verify(token),
        throwsA(isA<InvalidAccessTokenException>()),
      );
    });

    test('rejects an unknown role', () {
      final token =
          JWT(
            <String, dynamic>{
              'sid': sessionId.oid,
              'role': 'superadmin',
            },
            subject: userId.oid,
            issuer: accessTokenIssuer,
            audience: Audience.one(accessTokenAudience),
            jwtId: 'fake-unknown-role-jti001',
          ).sign(
            SecretKey(fakeSecret),
            expiresIn: accessTokenLifetime,
          );

      expect(
        () => service.verify(token),
        throwsA(isA<InvalidAccessTokenException>()),
      );
    });

    test('rejects a non-HS256 token', () {
      final token =
          JWT(
            <String, dynamic>{
              'sid': sessionId.oid,
              'role': UserRole.customer.wireValue,
            },
            subject: userId.oid,
            issuer: accessTokenIssuer,
            audience: Audience.one(accessTokenAudience),
            jwtId: 'fake-hs384-alg-jti-value1',
          ).sign(
            SecretKey(fakeSecret),
            algorithm: JWTAlgorithm.HS384,
            expiresIn: accessTokenLifetime,
          );

      expect(headerOf(token)['alg'], equals('HS384'));
      expect(
        () => service.verify(token),
        throwsA(isA<InvalidAccessTokenException>()),
      );
    });

    test('rejects a missing secret', () {
      expect(
        () => JwtAccessTokenService(secret: ''),
        throwsA(isA<AccessTokenConfigurationException>()),
      );
      expect(
        () => JwtAccessTokenService.fromConfig(
          const ServerConfig(
            environment: 'development',
            allowedOrigins: <String>[],
          ),
        ),
        throwsA(isA<AccessTokenConfigurationException>()),
      );
    });

    test('rejects a short secret', () {
      expect(
        () => JwtAccessTokenService(secret: 'short-secret'),
        throwsA(isA<AccessTokenConfigurationException>()),
      );
    });
  });
}
