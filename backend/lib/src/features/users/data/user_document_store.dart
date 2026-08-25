import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Result of inserting a user document without exposing driver types.
class UserInsertResult {
  const UserInsertResult._({
    required this.isSuccess,
    required this.isDuplicateKey,
  });

  /// Insert acknowledged without write errors.
  const UserInsertResult.success()
    : this._(isSuccess: true, isDuplicateKey: false);

  /// Unique index rejected the insert (MongoDB code 11000).
  const UserInsertResult.duplicate()
    : this._(isSuccess: false, isDuplicateKey: true);

  /// Insert failed for a non-duplicate reason.
  const UserInsertResult.failed()
    : this._(isSuccess: false, isDuplicateKey: false);

  /// Whether the write completed successfully.
  final bool isSuccess;

  /// Whether the failure was a duplicate-key error.
  final bool isDuplicateKey;
}

/// Result of updating a user document without exposing driver types.
class UserUpdateResult {
  const UserUpdateResult._({
    required this.isSuccess,
    required this.matched,
  });

  /// Update acknowledged and matched one document.
  const UserUpdateResult.success() : this._(isSuccess: true, matched: true);

  /// Selector matched no document.
  const UserUpdateResult.notFound() : this._(isSuccess: false, matched: false);

  /// Update failed for a write or driver reason.
  const UserUpdateResult.failed() : this._(isSuccess: false, matched: false);

  /// Whether the write completed successfully against a matched document.
  final bool isSuccess;

  /// Whether a document matched the selector.
  final bool matched;
}

/// Narrow collection access used by MongoUserRepository.
abstract class UserDocumentStore {
  /// Finds a single document matching [selector], or `null`.
  Future<Map<String, dynamic>?> findOne(Map<String, dynamic> selector);

  /// Finds documents matching [selector], optionally sorted and limited.
  Future<List<Map<String, dynamic>>> findMany(
    Map<String, dynamic> selector, {
    Map<String, int>? sort,
    int? limit,
  });

  /// Inserts [document]. Must not log document contents.
  Future<UserInsertResult> insertOne(Map<String, dynamic> document);

  /// Updates one document matching [selector]. Must not log contents.
  Future<UserUpdateResult> updateOne({
    required Map<String, dynamic> selector,
    required Map<String, dynamic> update,
  });
}

/// mongo_dart-backed [UserDocumentStore].
class MongoUserDocumentStore implements UserDocumentStore {
  /// Wraps an already-selected collection.
  MongoUserDocumentStore(this._collection);

  /// Convenience constructor using [CollectionNames.users].
  MongoUserDocumentStore.fromDb(Db db)
    : _collection = db.collection(CollectionNames.users);

  final DbCollection _collection;

  @override
  Future<Map<String, dynamic>?> findOne(Map<String, dynamic> selector) {
    return _collection.findOne(selector);
  }

  @override
  Future<List<Map<String, dynamic>>> findMany(
    Map<String, dynamic> selector, {
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

  @override
  Future<UserInsertResult> insertOne(Map<String, dynamic> document) async {
    final result = await _collection.insertOne(document);
    if (result.writeError?.code == 11000) {
      return const UserInsertResult.duplicate();
    }
    if (!result.isSuccess) {
      return const UserInsertResult.failed();
    }
    return const UserInsertResult.success();
  }

  @override
  Future<UserUpdateResult> updateOne({
    required Map<String, dynamic> selector,
    required Map<String, dynamic> update,
  }) async {
    final result = await _collection.updateOne(selector, update);
    if (!result.isSuccess) {
      return const UserUpdateResult.failed();
    }
    if (result.nMatched < 1) {
      return const UserUpdateResult.notFound();
    }
    return const UserUpdateResult.success();
  }
}
