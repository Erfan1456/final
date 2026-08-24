import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

void main() {
  final id = ObjectId.fromHexString('507f1f77bcf86cd799439021');
  final userId = ObjectId.fromHexString('507f1f77bcf86cd799439022');
  final createdAt = DateTime.utc(2026, 8, 25, 12);
  final lastRotatedAt = DateTime.utc(2026, 8, 25, 13);
  final expiresAt = DateTime.utc(2026, 9, 24, 12);
  const currentHash =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const usedHash =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  Map<String, dynamic> stored({
    List<String> used = const <String>[],
    DateTime? revokedAt,
  }) {
    return <String, dynamic>{
      '_id': id,
      'user_id': userId,
      'refresh_token_hash': currentHash,
      'used_refresh_token_hashes': used,
      'expires_at': expiresAt,
      'revoked_at': revokedAt,
      'created_at': createdAt,
      'last_rotated_at': lastRotatedAt,
    };
  }

  group('UserSession', () {
    test('round-trips BSON with an empty used-token list', () {
      final session = UserSession.fromDocument(stored());

      expect(session.id, equals(id));
      expect(session.userId, equals(userId));
      expect(session.refreshTokenHash, equals(currentHash));
      expect(session.usedRefreshTokenHashes, isEmpty);
      expect(session.expiresAt, equals(expiresAt));
      expect(session.revokedAt, isNull);
      expect(session.createdAt.isUtc, isTrue);
      expect(session.lastRotatedAt.isUtc, isTrue);
      expect(session.toDocument()['_id'], equals(id));
    });

    test('round-trips a rotated used-token list and revocation', () {
      final revokedAt = DateTime.utc(2026, 8, 26, 1);
      final session = UserSession.fromDocument(
        stored(used: <String>[usedHash], revokedAt: revokedAt),
      );

      expect(session.usedRefreshTokenHashes, equals(<String>[usedHash]));
      expect(session.revokedAt, equals(revokedAt));
      expect(session.isRevoked, isTrue);
      expect(
        session.toDocument()['used_refresh_token_hashes'],
        equals(<String>[usedHash]),
      );
    });

    test('fails for missing required fields and wrong types', () {
      expect(
        () => UserSession.fromDocument(<String, dynamic>{}),
        throwsA(isA<UserSessionDocumentException>()),
      );
      expect(
        () => UserSession.fromDocument(stored()..['_id'] = 'not-an-id'),
        throwsA(isA<UserSessionDocumentException>()),
      );
      expect(
        () => UserSession.fromDocument(stored()..['expires_at'] = 'now'),
        throwsA(isA<UserSessionDocumentException>()),
      );
      expect(
        () => UserSession.fromDocument(
          stored()..['used_refresh_token_hashes'] = <int>[1],
        ),
        throwsA(isA<UserSessionDocumentException>()),
      );
    });

    test('toString does not expose token hashes', () {
      final session = UserSession.fromDocument(
        stored(used: <String>[usedHash]),
      );

      expect('$session', isNot(contains(currentHash)));
      expect('$session', isNot(contains(usedHash)));
      expect('$session', contains(id.oid));
    });
  });
}
