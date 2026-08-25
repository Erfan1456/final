import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/document_write_results.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// In-memory [CollectionDocumentStore] for Atlas-free repository tests.
class MemoryCollectionDocumentStore implements CollectionDocumentStore {
  /// Creates an empty store.
  MemoryCollectionDocumentStore();

  /// Stored documents.
  final List<Map<String, dynamic>> documents = <Map<String, dynamic>>[];

  /// Forced insert result, if set.
  DocumentInsertResult? insertResult;

  /// Forced update result, if set.
  DocumentUpdateResult? updateResult;

  /// Last update selector observed.
  Map<String, dynamic>? lastUpdateSelector;

  /// Last delete selector observed.
  Map<String, dynamic>? lastDeleteSelector;

  /// Number of [findOne] invocations.
  int findOneCalls = 0;

  /// Number of [findMany] invocations.
  int findManyCalls = 0;

  @override
  Future<Map<String, dynamic>?> findOne(Map<String, dynamic> selector) async {
    findOneCalls += 1;
    for (final document in documents) {
      if (documentMatches(document, selector)) {
        return Map<String, dynamic>.from(document);
      }
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> findMany({
    required Map<String, dynamic> selector,
    Map<String, int>? sort,
    int? limit,
  }) async {
    findManyCalls += 1;
    final matched = [
      for (final document in documents)
        if (documentMatches(document, selector))
          Map<String, dynamic>.from(document),
    ];
    if (sort != null && sort.isNotEmpty) {
      matched.sort((a, b) {
        for (final entry in sort.entries) {
          final left = a[entry.key];
          final right = b[entry.key];
          final comparison = _compare(left, right);
          if (comparison != 0) {
            return entry.value < 0 ? -comparison : comparison;
          }
        }
        return 0;
      });
    }
    if (limit != null && matched.length > limit) {
      return matched.sublist(0, limit);
    }
    return matched;
  }

  @override
  Future<int> count(Map<String, dynamic> selector) async {
    return documents
        .where((document) => documentMatches(document, selector))
        .length;
  }

  @override
  Future<DocumentInsertResult> insertOne(Map<String, dynamic> document) async {
    final forced = insertResult;
    if (forced != null) {
      return forced;
    }
    documents.add(Map<String, dynamic>.from(document));
    return const DocumentInsertResult.success();
  }

  @override
  Future<DocumentUpdateResult> updateOne({
    required Map<String, dynamic> selector,
    required Map<String, dynamic> update,
    bool upsert = false,
  }) async {
    lastUpdateSelector = Map<String, dynamic>.from(selector);
    final forced = updateResult;
    if (forced != null) {
      return forced;
    }
    for (final document in documents) {
      if (!documentMatches(document, selector)) {
        continue;
      }
      _applyUpdate(document, update, inserting: false);
      return const DocumentUpdateResult.success();
    }
    if (!upsert) {
      return const DocumentUpdateResult.notFound();
    }
    final created = <String, dynamic>{};
    _applyUpdate(created, update, inserting: true);
    documents.add(created);
    return const DocumentUpdateResult.upserted();
  }

  @override
  Future<DocumentDeleteResult> deleteOne(Map<String, dynamic> selector) async {
    lastDeleteSelector = Map<String, dynamic>.from(selector);
    final index = documents.indexWhere(
      (document) => documentMatches(document, selector),
    );
    if (index < 0) {
      return const DocumentDeleteResult.notFound();
    }
    documents.removeAt(index);
    return const DocumentDeleteResult.success();
  }
}

/// Whether [document] matches a Mongo-style [selector] used in tests.
bool documentMatches(
  Map<String, dynamic> document,
  Map<String, dynamic> selector,
) {
  for (final entry in selector.entries) {
    if (entry.key == r'$and' && entry.value is List) {
      for (final clause in entry.value as List) {
        if (clause is! Map ||
            !documentMatches(document, Map<String, dynamic>.from(clause))) {
          return false;
        }
      }
      continue;
    }
    if (!_fieldMatches(document[entry.key], entry.value)) {
      return false;
    }
  }
  return true;
}

bool _fieldMatches(Object? actual, Object? expected) {
  if (expected is Map) {
    for (final entry in expected.entries) {
      switch (entry.key) {
        case r'$in':
          final options = entry.value;
          if (options is! List || !options.any((option) => actual == option)) {
            return false;
          }
        case r'$gt':
          if (_compare(actual, entry.value) <= 0) {
            return false;
          }
        case r'$gte':
          if (_compare(actual, entry.value) < 0) {
            return false;
          }
        case r'$lt':
          if (_compare(actual, entry.value) >= 0) {
            return false;
          }
        case r'$lte':
          if (_compare(actual, entry.value) > 0) {
            return false;
          }
        case r'$ne':
          if (actual == entry.value) {
            return false;
          }
        default:
          return false;
      }
    }
    return true;
  }
  return actual == expected;
}

void _applyUpdate(
  Map<String, dynamic> document,
  Map<String, dynamic> update, {
  required bool inserting,
}) {
  if (inserting) {
    final setOnInsert = update[r'$setOnInsert'];
    if (setOnInsert is Map) {
      setOnInsert.forEach((key, value) {
        document[key.toString()] = value;
      });
    }
  }
  final set = update[r'$set'];
  if (set is Map) {
    set.forEach((key, value) {
      document[key.toString()] = value;
    });
  }
  final unset = update[r'$unset'];
  if (unset is Map) {
    for (final key in unset.keys) {
      document.remove(key.toString());
    }
  }
}

int _compare(Object? left, Object? right) {
  if (left is ObjectId && right is ObjectId) {
    return left.oid.compareTo(right.oid);
  }
  if (left is DateTime && right is DateTime) {
    return left.compareTo(right);
  }
  if (left is String && right is String) {
    return left.compareTo(right);
  }
  if (left is num && right is num) {
    return left.compareTo(right);
  }
  final leftId = left?.toString();
  final rightId = right?.toString();
  if (leftId != null && rightId != null) {
    return leftId.compareTo(rightId);
  }
  return 0;
}
