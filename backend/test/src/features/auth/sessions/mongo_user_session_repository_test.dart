import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/create_user_session_data.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/mongo_user_session_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/session_document_store.dart';
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
    final hash = document['refresh_token_hash'];
    if (hash is String &&
        documents.any((item) => item['refresh_token_hash'] == hash)) {
      return const SessionInsertResult.duplicate();
    }
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
    for (var i = 0; i < documents.length; i++) {
      if (!_matches(documents[i], query)) {
        continue;
      }
      _applyUpdate(documents[i], update);
      final updated = Map<String, dynamic>.from(documents[i]);
      return returnNew ? updated : updated;
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
  final userId = ObjectId.fromHexString('507f1f77bcf86cd799439031');
  const currentHash =
      '1111111111111111111111111111111111111111111111111111111111111111';
  const nextHash =
      '2222222222222222222222222222222222222222222222222222222222222222';
  final expiresAt = DateTime.utc(2026, 9, 24, 12);

  group('MongoUserSessionRepository', () {
    test('create stores only the token hash', () async {
      final store = _MemorySessionDocuments();
      final repository = MongoUserSessionRepository(documents: store);

      final session = await repository.create(
        CreateUserSessionData(
          userId: userId,
          refreshTokenHash: currentHash,
          expiresAt: expiresAt,
        ),
      );

      expect(session.refreshTokenHash, equals(currentHash));
      expect(session.usedRefreshTokenHashes, isEmpty);
      expect(session.revokedAt, isNull);
      expect(store.documents.single['refresh_token_hash'], equals(currentHash));
      expect(store.documents.single.containsKey('raw_refresh_token'), isFalse);
    });

    test('finds by current hash and used hash after rotation', () async {
      final store = _MemorySessionDocuments();
      final repository = MongoUserSessionRepository(documents: store);
      final created = await repository.create(
        CreateUserSessionData(
          userId: userId,
          refreshTokenHash: currentHash,
          expiresAt: expiresAt,
        ),
      );
      final now = DateTime.utc(2026, 8, 25, 14);

      final rotated = await repository.rotateCurrentTokenAtomically(
        currentRefreshTokenHash: currentHash,
        newRefreshTokenHash: nextHash,
        now: now,
      );

      expect(rotated, isNotNull);
      expect(rotated!.id, equals(created.id));
      expect(rotated.refreshTokenHash, equals(nextHash));
      expect(rotated.usedRefreshTokenHashes, equals(<String>[currentHash]));
      expect(rotated.expiresAt, equals(created.expiresAt));
      expect(rotated.lastRotatedAt, equals(now));
      expect(
        await repository.findByCurrentRefreshTokenHash(nextHash),
        isNotNull,
      );
      expect(
        await repository.findByUsedRefreshTokenHash(currentHash),
        isNotNull,
      );
    });

    test('rejects rotation after revoke or expiry', () async {
      final store = _MemorySessionDocuments();
      final repository = MongoUserSessionRepository(documents: store);
      final created = await repository.create(
        CreateUserSessionData(
          userId: userId,
          refreshTokenHash: currentHash,
          expiresAt: expiresAt,
        ),
      );

      await repository.revokeById(
        created.id,
        now: DateTime.utc(2026, 8, 25, 15),
      );
      expect(
        await repository.rotateCurrentTokenAtomically(
          currentRefreshTokenHash: currentHash,
          newRefreshTokenHash: nextHash,
          now: DateTime.utc(2026, 8, 25, 16),
        ),
        isNull,
      );

      final expiredStore = _MemorySessionDocuments();
      final expiredRepo = MongoUserSessionRepository(documents: expiredStore);
      await expiredRepo.create(
        CreateUserSessionData(
          userId: userId,
          refreshTokenHash: currentHash,
          expiresAt: DateTime.utc(2026, 8, 2),
        ),
      );
      expect(
        await expiredRepo.rotateCurrentTokenAtomically(
          currentRefreshTokenHash: currentHash,
          newRefreshTokenHash: nextHash,
          now: DateTime.utc(2026, 8, 25),
        ),
        isNull,
      );
    });

    test(
      'revoke by id is idempotent and revoke-all updates matching users',
      () async {
        final store = _MemorySessionDocuments();
        final repository = MongoUserSessionRepository(documents: store);
        final first = await repository.create(
          CreateUserSessionData(
            userId: userId,
            refreshTokenHash: currentHash,
            expiresAt: expiresAt,
          ),
        );
        final otherUser = ObjectId.fromHexString('507f1f77bcf86cd799439099');
        await repository.create(
          CreateUserSessionData(
            userId: otherUser,
            refreshTokenHash: nextHash,
            expiresAt: expiresAt,
          ),
        );

        final now = DateTime.utc(2026, 8, 25, 18);
        final revoked = await repository.revokeById(first.id, now: now);
        final again = await repository.revokeById(first.id, now: now);

        expect(revoked!.revokedAt, equals(now));
        expect(again!.revokedAt, equals(now));
        expect(await repository.revokeAllForUser(userId, now: now), equals(0));
        expect(
          await repository.revokeAllForUser(otherUser, now: now),
          equals(1),
        );
      },
    );

    test(
      'only one concurrent rotation of the same current hash succeeds',
      () async {
        final store = _MemorySessionDocuments();
        final repository = MongoUserSessionRepository(documents: store);
        await repository.create(
          CreateUserSessionData(
            userId: userId,
            refreshTokenHash: currentHash,
            expiresAt: expiresAt,
          ),
        );
        final now = DateTime.utc(2026, 8, 25, 19);

        final results = await Future.wait(<Future<Object?>>[
          repository.rotateCurrentTokenAtomically(
            currentRefreshTokenHash: currentHash,
            newRefreshTokenHash: '3' * 64,
            now: now,
          ),
          repository.rotateCurrentTokenAtomically(
            currentRefreshTokenHash: currentHash,
            newRefreshTokenHash: '4' * 64,
            now: now,
          ),
        ]);

        final successes = results.where((item) => item != null);
        expect(successes, hasLength(1));
      },
    );
  });
}
