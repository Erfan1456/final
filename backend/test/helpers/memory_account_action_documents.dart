import 'package:home_cleaning_marketplace_api/src/features/account_actions/data/account_action_token_document_store.dart';

/// In-memory account-action token store for Atlas-free tests.
class MemoryAccountActionDocuments implements AccountActionTokenDocumentStore {
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
  Future<AccountActionInsertResult> insertOne(
    Map<String, dynamic> document,
  ) async {
    final hash = document['token_hash'];
    if (hash is String &&
        documents.any((item) => item['token_hash'] == hash)) {
      return const AccountActionInsertResult.duplicate();
    }
    documents.add(Map<String, dynamic>.from(document));
    return const AccountActionInsertResult.success();
  }

  @override
  Future<Map<String, dynamic>?> findAndModify({
    required Map<String, dynamic> query,
    required Map<String, dynamic> update,
    required bool returnNew,
  }) async {
    for (var i = 0; i < documents.length; i++) {
      if (!_matches(documents[i], query)) {
        continue;
      }
      _applyUpdate(documents[i], update);
      return Map<String, dynamic>.from(documents[i]);
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
  }) async {
    return [
      for (final document in documents)
        if (_matches(document, selector)) Map<String, dynamic>.from(document),
    ];
  }

  void _applyUpdate(Map<String, dynamic> document, Map<String, dynamic> update) {
    final set = update[r'$set'];
    if (set is Map) {
      document.addAll(Map<String, dynamic>.from(set));
    }
  }

  bool _matches(Map<String, dynamic> document, Map<String, dynamic> selector) {
    for (final entry in selector.entries) {
      final value = entry.value;
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
}
