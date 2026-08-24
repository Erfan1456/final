import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/create_user_session_data.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/session_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session_repository.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// MongoDB implementation of [UserSessionRepository].
///
/// Receives a [Db] or a [SessionDocumentStore]. It does not read environment
/// variables, construct a MongoDatabase instance, generate refresh tokens, or
/// create JWTs.
class MongoUserSessionRepository implements UserSessionRepository {
  /// Creates a repository over [documents].
  MongoUserSessionRepository({required SessionDocumentStore documents})
    : _documents = documents;

  /// Creates a repository using the user_sessions collection on [db].
  factory MongoUserSessionRepository.fromDb(Db db) {
    return MongoUserSessionRepository(
      documents: MongoSessionDocumentStore.fromDb(db),
    );
  }

  final SessionDocumentStore _documents;

  @override
  Future<UserSession> create(CreateUserSessionData data) async {
    final now = DateTime.now().toUtc();
    final session = UserSession(
      id: ObjectId(),
      userId: data.userId,
      refreshTokenHash: data.refreshTokenHash,
      usedRefreshTokenHashes: const <String>[],
      expiresAt: data.expiresAt.toUtc(),
      createdAt: now,
      lastRotatedAt: now,
    );

    final result = await _documents.insertOne(session.toDocument());
    if (!result.isSuccess) {
      throw const UserSessionWriteException();
    }
    return session;
  }

  @override
  Future<UserSession?> findById(ObjectId id) {
    return _find(<String, dynamic>{'_id': id});
  }

  @override
  Future<UserSession?> findByCurrentRefreshTokenHash(String hash) {
    return _find(<String, dynamic>{'refresh_token_hash': hash});
  }

  @override
  Future<UserSession?> findByUsedRefreshTokenHash(String hash) {
    return _find(<String, dynamic>{'used_refresh_token_hashes': hash});
  }

  @override
  Future<UserSession?> rotateCurrentTokenAtomically({
    required String currentRefreshTokenHash,
    required String newRefreshTokenHash,
    required DateTime now,
  }) {
    return _modify(
      query: <String, dynamic>{
        'refresh_token_hash': currentRefreshTokenHash,
        'revoked_at': null,
        'expires_at': <String, dynamic>{r'$gt': now.toUtc()},
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'refresh_token_hash': newRefreshTokenHash,
          'last_rotated_at': now.toUtc(),
        },
        r'$push': <String, dynamic>{
          'used_refresh_token_hashes': currentRefreshTokenHash,
        },
      },
    );
  }

  @override
  Future<UserSession?> revokeById(ObjectId id, {required DateTime now}) async {
    final updated = await _modify(
      query: <String, dynamic>{
        '_id': id,
        'revoked_at': null,
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{'revoked_at': now.toUtc()},
      },
    );
    if (updated != null) {
      return updated;
    }
    return findById(id);
  }

  @override
  Future<int> revokeAllForUser(ObjectId userId, {required DateTime now}) {
    return _documents.updateMany(
      query: <String, dynamic>{
        'user_id': userId,
        'revoked_at': null,
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{'revoked_at': now.toUtc()},
      },
    );
  }

  Future<UserSession?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return UserSession.fromDocument(document);
  }

  Future<UserSession?> _modify({
    required Map<String, dynamic> query,
    required Map<String, dynamic> update,
  }) async {
    final document = await _documents.findAndModify(
      query: query,
      update: update,
      returnNew: true,
    );
    if (document == null) {
      return null;
    }
    return UserSession.fromDocument(document);
  }
}
