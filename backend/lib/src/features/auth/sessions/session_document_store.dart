import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Result of inserting a session document without exposing driver types.
class SessionInsertResult {
  const SessionInsertResult._({
    required this.isSuccess,
    required this.isDuplicateKey,
  });

  /// Insert acknowledged without write errors.
  const SessionInsertResult.success()
    : this._(isSuccess: true, isDuplicateKey: false);

  /// Unique index rejected the insert (MongoDB code 11000).
  const SessionInsertResult.duplicate()
    : this._(isSuccess: false, isDuplicateKey: true);

  /// Insert failed for a non-duplicate reason.
  const SessionInsertResult.failed()
    : this._(isSuccess: false, isDuplicateKey: false);

  /// Whether the write completed successfully.
  final bool isSuccess;

  /// Whether the failure was a duplicate-key error.
  final bool isDuplicateKey;
}

/// Narrow collection access used by MongoUserSessionRepository.
abstract class SessionDocumentStore {
  /// Finds a single document matching [selector], or `null`.
  Future<Map<String, dynamic>?> findOne(Map<String, dynamic> selector);

  /// Inserts [document]. Must not log document contents.
  Future<SessionInsertResult> insertOne(Map<String, dynamic> document);

  /// Atomically finds and updates one document. Returns the selected document
  /// after modification when [returnNew] is true.
  Future<Map<String, dynamic>?> findAndModify({
    required Map<String, dynamic> query,
    required Map<String, dynamic> update,
    required bool returnNew,
  });

  /// Updates all documents matching [query]. Returns the modified count.
  Future<int> updateMany({
    required Map<String, dynamic> query,
    required Map<String, dynamic> update,
  });

  /// Finds documents matching [selector], optionally sorted and limited.
  Future<List<Map<String, dynamic>>> findMany({
    required Map<String, dynamic> selector,
    Map<String, int>? sort,
    int? limit,
  });
}

/// mongo_dart-backed [SessionDocumentStore].
class MongoSessionDocumentStore implements SessionDocumentStore {
  /// Wraps an already-selected collection.
  MongoSessionDocumentStore(this._collection);

  /// Convenience constructor using [CollectionNames.userSessions].
  MongoSessionDocumentStore.fromDb(Db db)
    : _collection = db.collection(CollectionNames.userSessions);

  final DbCollection _collection;

  @override
  Future<Map<String, dynamic>?> findOne(Map<String, dynamic> selector) {
    return _collection.findOne(selector);
  }

  @override
  Future<SessionInsertResult> insertOne(Map<String, dynamic> document) async {
    final result = await _collection.insertOne(document);
    if (result.writeError?.code == 11000) {
      return const SessionInsertResult.duplicate();
    }
    if (!result.isSuccess) {
      return const SessionInsertResult.failed();
    }
    return const SessionInsertResult.success();
  }

  @override
  Future<Map<String, dynamic>?> findAndModify({
    required Map<String, dynamic> query,
    required Map<String, dynamic> update,
    required bool returnNew,
  }) {
    return _collection.findAndModify(
      query: query,
      update: update,
      returnNew: returnNew,
    );
  }

  @override
  Future<int> updateMany({
    required Map<String, dynamic> query,
    required Map<String, dynamic> update,
  }) async {
    final result = await _collection.updateMany(query, update);
    return result.nModified;
  }

  @override
  Future<List<Map<String, dynamic>>> findMany({
    required Map<String, dynamic> selector,
    Map<String, int>? sort,
    int? limit,
  }) {
    return _collection
        .modernFind(
          filter: selector,
          sort: sort == null ? null : Map<String, Object>.from(sort),
          limit: limit,
        )
        .toList();
  }
}
