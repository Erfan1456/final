import 'package:home_cleaning_marketplace_api/src/database/document_write_results.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Narrow collection access used by feature repositories.
abstract class CollectionDocumentStore {
  /// Finds a single document matching [selector], or `null`.
  Future<Map<String, dynamic>?> findOne(Map<String, dynamic> selector);

  /// Finds documents matching [selector], optionally sorted and limited.
  Future<List<Map<String, dynamic>>> findMany({
    required Map<String, dynamic> selector,
    Map<String, int>? sort,
    int? limit,
  });

  /// Counts documents matching [selector].
  Future<int> count(Map<String, dynamic> selector);

  /// Inserts [document]. Must not log document contents.
  Future<DocumentInsertResult> insertOne(Map<String, dynamic> document);

  /// Updates one document matching [selector]. Must not log contents.
  Future<DocumentUpdateResult> updateOne({
    required Map<String, dynamic> selector,
    required Map<String, dynamic> update,
    bool upsert = false,
  });

  /// Deletes one document matching [selector].
  Future<DocumentDeleteResult> deleteOne(Map<String, dynamic> selector);
}

/// mongo_dart-backed [CollectionDocumentStore].
class MongoCollectionDocumentStore implements CollectionDocumentStore {
  /// Wraps an already-selected collection.
  MongoCollectionDocumentStore(this._collection);

  final DbCollection _collection;

  @override
  Future<Map<String, dynamic>?> findOne(Map<String, dynamic> selector) {
    return _collection.findOne(selector);
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

  @override
  Future<int> count(Map<String, dynamic> selector) {
    return _collection.count(selector);
  }

  @override
  Future<DocumentInsertResult> insertOne(Map<String, dynamic> document) async {
    final result = await _collection.insertOne(document);
    if (result.writeError?.code == 11000) {
      return const DocumentInsertResult.duplicate();
    }
    if (!result.isSuccess) {
      return const DocumentInsertResult.failed();
    }
    return const DocumentInsertResult.success();
  }

  @override
  Future<DocumentUpdateResult> updateOne({
    required Map<String, dynamic> selector,
    required Map<String, dynamic> update,
    bool upsert = false,
  }) async {
    final result = await _collection.updateOne(
      selector,
      update,
      upsert: upsert,
    );
    if (result.writeError?.code == 11000) {
      return const DocumentUpdateResult.failed();
    }
    if (!result.isSuccess) {
      return const DocumentUpdateResult.failed();
    }
    if (result.nUpserted > 0) {
      return const DocumentUpdateResult.upserted();
    }
    if (result.nMatched < 1) {
      return const DocumentUpdateResult.notFound();
    }
    return const DocumentUpdateResult.success();
  }

  @override
  Future<DocumentDeleteResult> deleteOne(Map<String, dynamic> selector) async {
    final result = await _collection.deleteOne(selector);
    if (!result.isSuccess) {
      return const DocumentDeleteResult.failed();
    }
    if (result.nRemoved < 1) {
      return const DocumentDeleteResult.notFound();
    }
    return const DocumentDeleteResult.success();
  }
}
