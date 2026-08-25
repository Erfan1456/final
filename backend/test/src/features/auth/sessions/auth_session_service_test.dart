import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/auth_session_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/mongo_user_session_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/session_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

class _MemorySessionDocuments implements SessionDocumentStore {
  final documents = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>?> findOne(Map<String, dynamic> selector) async {
    for (final document in documents) {
      if (_matches(document, selector)) {
        return Map<String, dynamic>.from(document);
      }
    }
    return null;
  }

  @override
  Future<SessionInsertResult> insertOne(Map<String, dynamic> document) async {
    documents.add(Map<String, dynamic>.from(document));
    return const SessionInsertResult.success();
  }

  @override
  Future<Map<String, dynamic>?> findAndModify({
    required Map<String, dynamic> query,
    required Map<String, dynamic> update,
    required bool returnNew,
  }) async {
    await Future<void>.value();
    for (final document in documents) {
      if (!_matches(document, query)) {
        continue;
      }
      _applyUpdate(document, update);
      return Map<String, dynamic>.from(document);
    }
    return null;
  }

  @override
  Future<int> updateMany({
    required Map<String, dynamic> query,
    required Map<String, dynamic> update,
  }) async {
    var count = 0;
    for (final document in documents) {
      if (_matches(document, query)) {
        _applyUpdate(document, update);
        count += 1;
      }
    }
    return count;
  }

  @override
  Future<List<Map<String, dynamic>>> findMany({
    required Map<String, dynamic> selector,
    Map<String, int>? sort,
    int? limit,
  }) async {
    var matches = [
      for (final document in documents)
        if (_matches(document, selector)) Map<String, dynamic>.from(document),
    ];
    if (sort != null && sort.isNotEmpty) {
      final field = sort.keys.first;
      final direction = sort[field] ?? 1;
      matches.sort((left, right) {
        final a = left[field];
        final b = right[field];
        if (a is DateTime && b is DateTime) {
          return direction < 0 ? b.compareTo(a) : a.compareTo(b);
        }
        return 0;
      });
    }
    if (limit != null && matches.length > limit) {
      matches = matches.sublist(0, limit);
    }
    return matches;
  }

  bool _matches(Map<String, dynamic> document, Map<String, dynamic> selector) {
    for (final entry in selector.entries) {
      final value = entry.value;
      if (entry.key == 'used_refresh_token_hashes' && value is String) {
        final used = document['used_refresh_token_hashes'];
        if (used is! List || !used.contains(value)) {
          return false;
        }
        continue;
      }
      if (value is Map && value.containsKey(r'$gt')) {
        final field = document[entry.key];
        final bound = value[r'$gt'];
        if (field is! DateTime || bound is! DateTime || !field.isAfter(bound)) {
          return false;
        }
        continue;
      }
      if (value == null) {
        if (document[entry.key] != null) {
          return false;
        }
        continue;
      }
      if (document[entry.key] != value) {
        return false;
      }
    }
    return true;
  }

  void _applyUpdate(
    Map<String, dynamic> document,
    Map<String, dynamic> update,
  ) {
    final set = update[r'$set'];
    if (set is Map) {
      set.forEach((key, value) {
        document[key.toString()] = value;
      });
    }
    final push = update[r'$push'];
    if (push is Map) {
      push.forEach((key, value) {
        final field = key.toString();
        final current = document[field];
        document[field] =
            (current is List ? List<dynamic>.from(current) : <dynamic>[])
              ..add(value);
      });
    }
  }
}

void main() {
  final userId = ObjectId.fromHexString('507f1f77bcf86cd799439041');
  final frozenNow = DateTime.utc(2026, 8, 25, 12);

  AuthSessionService serviceWith(_MemorySessionDocuments store) {
    return AuthSessionService(
      sessions: MongoUserSessionRepository(documents: store),
      clock: () => frozenNow,
    );
  }

  group('AuthSessionService', () {
    test(
      'createSession returns a raw token while persisting only the hash',
      () async {
        final store = _MemorySessionDocuments();
        final service = serviceWith(store);

        final issued = await service.createSession(userId);

        expect(issued.rawRefreshToken, isNotEmpty);
        expect(issued.session.userId, equals(userId));
        expect(
          issued.session.expiresAt.difference(frozenNow),
          equals(refreshSessionLifetime),
        );
        expect(
          store.documents.single['refresh_token_hash'],
          isNot(equals(issued.rawRefreshToken)),
        );
        expect(
          store.documents.single['refresh_token_hash'],
          equals(issued.session.refreshTokenHash),
        );
      },
    );

    test(
      'rotation returns a new raw token and does not extend expiry',
      () async {
        final store = _MemorySessionDocuments();
        final service = serviceWith(store);
        final created = await service.createSession(userId);
        final originalExpiry = created.session.expiresAt;

        final rotated = await service.rotateRefreshToken(
          created.rawRefreshToken,
        );

        expect(rotated.rawRefreshToken, isNot(equals(created.rawRefreshToken)));
        expect(rotated.session.expiresAt, equals(originalExpiry));
        expect(
          rotated.session.usedRefreshTokenHashes,
          contains(created.session.refreshTokenHash),
        );
        expect(
          store.documents.single['refresh_token_hash'],
          isNot(equals(rotated.rawRefreshToken)),
        );
      },
    );

    test('replay of a consumed token revokes the session', () async {
      final store = _MemorySessionDocuments();
      final service = serviceWith(store);
      final created = await service.createSession(userId);
      await service.rotateRefreshToken(created.rawRefreshToken);

      await expectLater(
        service.rotateRefreshToken(created.rawRefreshToken),
        throwsA(isA<RefreshTokenReuseDetectedException>()),
      );

      final session = UserSession.fromDocument(store.documents.single);
      expect(session.isRevoked, isTrue);
    });

    test('unknown, revoked, and expired tokens fail generically', () async {
      final store = _MemorySessionDocuments();
      final service = serviceWith(store);

      await expectLater(
        service.rotateRefreshToken('unknown-fake-refresh-token'),
        throwsA(isA<InvalidRefreshTokenException>()),
      );

      final created = await service.createSession(userId);
      await service.revokeSession(created.rawRefreshToken);
      await expectLater(
        service.rotateRefreshToken(created.rawRefreshToken),
        throwsA(isA<InvalidRefreshTokenException>()),
      );

      final expiredStore = _MemorySessionDocuments();
      final expiredService = AuthSessionService(
        sessions: MongoUserSessionRepository(documents: expiredStore),
        clock: () => DateTime.utc(2026, 8, 25),
      );
      final expired = await expiredService.createSession(userId);
      expiredStore.documents.single['expires_at'] = DateTime.utc(2026, 8, 2);
      await expectLater(
        expiredService.rotateRefreshToken(expired.rawRefreshToken),
        throwsA(isA<InvalidRefreshTokenException>()),
      );
    });

    test('revoke is safe for an already-revoked session', () async {
      final store = _MemorySessionDocuments();
      final service = serviceWith(store);
      final created = await service.createSession(userId);

      await service.revokeSession(created.rawRefreshToken);
      await service.revokeSession(created.rawRefreshToken);

      expect(
        UserSession.fromDocument(store.documents.single).isRevoked,
        isTrue,
      );
    });

    test('revoke-all delegates to every session for the user', () async {
      final store = _MemorySessionDocuments();
      final service = serviceWith(store);
      await service.createSession(userId);
      await service.createSession(userId);

      expect(await service.revokeAllForUser(userId), equals(2));
      expect(
        store.documents.every((document) => document['revoked_at'] != null),
        isTrue,
      );
    });

    test(
      'concurrent rotation cannot consume the same current token twice',
      () async {
        final store = _MemorySessionDocuments();
        final service = serviceWith(store);
        final created = await service.createSession(userId);

        final results = await Future.wait(<Future<Object>>[
          () async {
            try {
              return await service.rotateRefreshToken(created.rawRefreshToken);
            } on Exception catch (error) {
              return error;
            }
          }(),
          () async {
            try {
              return await service.rotateRefreshToken(created.rawRefreshToken);
            } on Exception catch (error) {
              return error;
            }
          }(),
        ]);

        final issued = results.whereType<IssuedRefreshSession>().toList();
        final failures = results.whereType<Exception>().toList();

        expect(issued, hasLength(1));
        expect(failures, hasLength(1));
        expect(
          failures.single,
          anyOf(
            isA<RefreshTokenReuseDetectedException>(),
            isA<InvalidRefreshTokenException>(),
          ),
        );
        expect(
          issued.single.rawRefreshToken,
          isNot(equals(created.rawRefreshToken)),
        );
      },
    );
  });
}
