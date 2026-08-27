import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Result of inserting an account-action token document.
class AccountActionInsertResult {
  const AccountActionInsertResult._({
    required this.isSuccess,
    required this.isDuplicateKey,
  });

  /// Insert acknowledged without write errors.
  const AccountActionInsertResult.success()
    : this._(isSuccess: true, isDuplicateKey: false);

  /// Unique index rejected the insert (MongoDB code 11000).
  const AccountActionInsertResult.duplicate()
    : this._(isSuccess: false, isDuplicateKey: true);

  /// Insert failed for a non-duplicate reason.
  const AccountActionInsertResult.failed()
    : this._(isSuccess: false, isDuplicateKey: false);

  /// Whether the write completed successfully.
  final bool isSuccess;

  /// Whether the failure was a duplicate-key error.
  final bool isDuplicateKey;
}

/// Narrow collection access used by the account-action token repository.
abstract class AccountActionTokenDocumentStore {
  /// Finds a single document matching [selector], or `null`.
  Future<Map<String, dynamic>?> findOne(Map<String, dynamic> selector);

  /// Finds documents matching [selector], optionally sorted.
  Future<List<Map<String, dynamic>>> findMany({
    required Map<String, dynamic> selector,
    Map<String, int>? sort,
  });

  /// Inserts [document]. Must not log document contents.
  Future<AccountActionInsertResult> insertOne(Map<String, dynamic> document);

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
}

/// mongo_dart-backed [AccountActionTokenDocumentStore].
class MongoAccountActionTokenDocumentStore
    implements AccountActionTokenDocumentStore {
  /// Wraps an already-selected collection.
  MongoAccountActionTokenDocumentStore(this._collection);

  /// Convenience constructor using [CollectionNames.accountActionTokens].
  MongoAccountActionTokenDocumentStore.fromDb(Db db)
    : _collection = db.collection(CollectionNames.accountActionTokens);

  final DbCollection _collection;

  @override
  Future<Map<String, dynamic>?> findOne(Map<String, dynamic> selector) {
    return _collection.findOne(selector);
  }

  @override
  Future<List<Map<String, dynamic>>> findMany({
    required Map<String, dynamic> selector,
    Map<String, int>? sort,
  }) {
    return _collection
        .modernFind(
          filter: selector,
          sort: sort == null ? null : Map<String, Object>.from(sort),
        )
        .toList();
  }

  @override
  Future<AccountActionInsertResult> insertOne(
    Map<String, dynamic> document,
  ) async {
    final result = await _collection.insertOne(document);
    if (result.writeError?.code == 11000) {
      return const AccountActionInsertResult.duplicate();
    }
    if (!result.isSuccess) {
      return const AccountActionInsertResult.failed();
    }
    return const AccountActionInsertResult.success();
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
}
