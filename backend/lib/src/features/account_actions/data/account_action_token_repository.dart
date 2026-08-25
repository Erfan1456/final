import 'package:home_cleaning_marketplace_api/src/features/account_actions/data/account_action_token_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_purpose.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_token.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for hashed one-time account-action tokens.
///
/// Does not accept raw tokens. Callers hash at the service boundary.
abstract class AccountActionTokenRepository {
  /// Sets `revoked_at` on live unclaimed tokens for [userId] and [purpose].
  Future<int> revokeLiveForUserAndPurpose({
    required ObjectId userId,
    required AccountActionPurpose purpose,
    required DateTime now,
  });

  /// Inserts a hashed token document.
  Future<AccountActionToken> create(AccountActionToken token);

  /// Atomically claims a live matching token by hash and purpose.
  Future<AccountActionToken?> claimByTokenHash({
    required String tokenHash,
    required AccountActionPurpose purpose,
    required DateTime now,
  });

  /// Returns a live matching token without claiming it.
  Future<AccountActionToken?> findLiveByTokenHash({
    required String tokenHash,
    required AccountActionPurpose purpose,
    required DateTime now,
  });

  /// Test/support lookup of tokens for [userId] and [purpose].
  Future<List<AccountActionToken>> findByUserAndPurpose({
    required ObjectId userId,
    required AccountActionPurpose purpose,
  });
}

/// MongoDB implementation of [AccountActionTokenRepository].
class MongoAccountActionTokenRepository
    implements AccountActionTokenRepository {
  /// Creates a repository over [documents].
  MongoAccountActionTokenRepository({
    required AccountActionTokenDocumentStore documents,
  }) : _documents = documents;

  /// Creates a repository using the account_action_tokens collection on [db].
  factory MongoAccountActionTokenRepository.fromDb(Db db) {
    return MongoAccountActionTokenRepository(
      documents: MongoAccountActionTokenDocumentStore.fromDb(db),
    );
  }

  final AccountActionTokenDocumentStore _documents;

  @override
  Future<int> revokeLiveForUserAndPurpose({
    required ObjectId userId,
    required AccountActionPurpose purpose,
    required DateTime now,
  }) {
    return _documents.updateMany(
      query: _liveSelector(
        extra: <String, dynamic>{
          'user_id': userId,
          'purpose': purpose.wireValue,
        },
        now: now,
      ),
      update: <String, dynamic>{
        r'$set': <String, dynamic>{'revoked_at': now.toUtc()},
      },
    );
  }

  @override
  Future<AccountActionToken> create(AccountActionToken token) async {
    final result = await _documents.insertOne(_toDocument(token));
    if (!result.isSuccess) {
      throw const AccountActionDocumentException(
        'Account-action token could not be stored.',
      );
    }
    return token;
  }

  @override
  Future<AccountActionToken?> claimByTokenHash({
    required String tokenHash,
    required AccountActionPurpose purpose,
    required DateTime now,
  }) {
    return _modify(
      query: _liveSelector(
        extra: <String, dynamic>{
          'token_hash': tokenHash,
          'purpose': purpose.wireValue,
        },
        now: now,
      ),
      update: <String, dynamic>{
        r'$set': <String, dynamic>{'claimed_at': now.toUtc()},
      },
    );
  }

  @override
  Future<AccountActionToken?> findLiveByTokenHash({
    required String tokenHash,
    required AccountActionPurpose purpose,
    required DateTime now,
  }) {
    return _find(
      _liveSelector(
        extra: <String, dynamic>{
          'token_hash': tokenHash,
          'purpose': purpose.wireValue,
        },
        now: now,
      ),
    );
  }

  @override
  Future<List<AccountActionToken>> findByUserAndPurpose({
    required ObjectId userId,
    required AccountActionPurpose purpose,
  }) async {
    final documents = await _documents.findMany(
      selector: <String, dynamic>{
        'user_id': userId,
        'purpose': purpose.wireValue,
      },
      sort: const <String, int>{'created_at': -1},
    );
    return [
      for (final document in documents) _fromDocument(document),
    ];
  }

  Map<String, dynamic> _liveSelector({
    required Map<String, dynamic> extra,
    required DateTime now,
  }) {
    return <String, dynamic>{
      ...extra,
      'claimed_at': null,
      'revoked_at': null,
      'expires_at': <String, dynamic>{r'$gt': now.toUtc()},
    };
  }

  Future<AccountActionToken?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return _fromDocument(document);
  }

  Future<AccountActionToken?> _modify({
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
    return _fromDocument(document);
  }

  Map<String, dynamic> _toDocument(AccountActionToken token) {
    return <String, dynamic>{
      '_id': token.id,
      'user_id': token.userId,
      'purpose': token.purpose.wireValue,
      'token_hash': token.tokenHash,
      'expires_at': token.expiresAt.toUtc(),
      'claimed_at': token.claimedAt?.toUtc(),
      'revoked_at': token.revokedAt?.toUtc(),
      'created_at': token.createdAt.toUtc(),
    };
  }

  AccountActionToken _fromDocument(Map<String, dynamic> document) {
    return AccountActionToken(
      id: _requireObjectId(document, '_id'),
      userId: _requireObjectId(document, 'user_id'),
      purpose: AccountActionPurpose.fromWire(
        _requireString(document, 'purpose'),
      ),
      tokenHash: _requireString(document, 'token_hash'),
      expiresAt: _requireUtcDateTime(document, 'expires_at'),
      claimedAt: _optionalUtcDateTime(document, 'claimed_at'),
      revokedAt: _optionalUtcDateTime(document, 'revoked_at'),
      createdAt: _requireUtcDateTime(document, 'created_at'),
    );
  }

  static ObjectId _requireObjectId(
    Map<String, dynamic> document,
    String field,
  ) {
    final value = document[field];
    if (value is ObjectId) {
      return value;
    }
    throw AccountActionDocumentException('$field must be ObjectId.');
  }

  static String _requireString(Map<String, dynamic> document, String field) {
    final value = document[field];
    if (value is String) {
      return value;
    }
    throw AccountActionDocumentException('$field must be String.');
  }

  static DateTime _requireUtcDateTime(
    Map<String, dynamic> document,
    String field,
  ) {
    final value = document[field];
    if (value is DateTime) {
      return value.toUtc();
    }
    throw AccountActionDocumentException('$field must be DateTime.');
  }

  static DateTime? _optionalUtcDateTime(
    Map<String, dynamic> document,
    String field,
  ) {
    if (!document.containsKey(field) || document[field] == null) {
      return null;
    }
    return _requireUtcDateTime(document, field);
  }
}
