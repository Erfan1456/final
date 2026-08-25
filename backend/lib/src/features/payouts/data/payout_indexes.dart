import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Unique cleaner + client idempotency key index.
const String payoutRequestsCleanerIdempotencyUniqueIndexName =
    'payout_requests_cleaner_idempotency_unique';

/// Partial unique active-payout index on cleaner_user_id.
const String payoutRequestsCleanerActiveUniqueIndexName =
    'payout_requests_cleaner_active_unique';

/// Cleaner list keyset index (`_id` descending).
const String payoutRequestsCleanerIdDescIndexName =
    'payout_requests_cleaner_id_desc';

/// Status list keyset index (`_id` descending).
const String payoutRequestsStatusIdDescIndexName =
    'payout_requests_status_id_desc';

/// Partial unique provider payout id index.
const String payoutRequestsProviderPayoutUniqueIndexName =
    'payout_requests_provider_payout_unique';

/// Cleaner owner field.
const String payoutRequestsCleanerUserIdField = 'cleaner_user_id';

/// Client idempotency key field.
const String payoutRequestsClientIdempotencyKeyField = 'client_idempotency_key';

/// Explicit active-payout concurrency field.
const String payoutRequestsPayoutActiveField = 'payout_active';

/// Status field.
const String payoutRequestsStatusField = 'status';

/// Provider field.
const String payoutRequestsProviderField = 'provider';

/// Provider payout id field.
const String payoutRequestsProviderPayoutIdField = 'provider_payout_id';

/// Function used to ensure a payout index without coupling tests to Atlas.
typedef EnsurePayoutIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
      Map<String, dynamic>? partialFilterExpression,
    });

/// Ensures the approved `payout_requests` indexes.
///
/// Active uniqueness uses `payout_active == true` rather than a `$in` status
/// partial filter, matching existing boolean partial unique indexes.
Future<void> ensurePayoutIndexes({
  required EnsurePayoutIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.payoutRequests,
    keys: const <String, dynamic>{
      payoutRequestsCleanerUserIdField: 1,
      payoutRequestsClientIdempotencyKeyField: 1,
    },
    unique: true,
    name: payoutRequestsCleanerIdempotencyUniqueIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.payoutRequests,
    keys: const <String, dynamic>{payoutRequestsCleanerUserIdField: 1},
    unique: true,
    name: payoutRequestsCleanerActiveUniqueIndexName,
    partialFilterExpression: const <String, dynamic>{
      payoutRequestsPayoutActiveField: true,
    },
  );
  await ensureIndex(
    collectionName: CollectionNames.payoutRequests,
    keys: const <String, dynamic>{
      payoutRequestsCleanerUserIdField: 1,
      '_id': -1,
    },
    unique: false,
    name: payoutRequestsCleanerIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.payoutRequests,
    keys: const <String, dynamic>{
      payoutRequestsStatusField: 1,
      '_id': -1,
    },
    unique: false,
    name: payoutRequestsStatusIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.payoutRequests,
    keys: const <String, dynamic>{
      payoutRequestsProviderField: 1,
      payoutRequestsProviderPayoutIdField: 1,
    },
    unique: true,
    name: payoutRequestsProviderPayoutUniqueIndexName,
    partialFilterExpression: const <String, dynamic>{
      payoutRequestsProviderPayoutIdField: <String, dynamic>{
        r'$type': 'string',
      },
    },
  );
}

/// Ensures approved payout indexes on [db], including partial unique.
Future<void> ensurePayoutIndexesOnDb(Db db) {
  return ensurePayoutIndexes(
    ensureIndex:
        ({
          required String collectionName,
          required Map<String, dynamic> keys,
          required bool unique,
          required String name,
          Map<String, dynamic>? partialFilterExpression,
        }) async {
          final collection = db.collection(collectionName);
          try {
            if (partialFilterExpression != null) {
              await db.runCommand(<String, Object>{
                'createIndexes': collectionName,
                'indexes': <Object>[
                  <String, Object>{
                    'key': Map<String, Object>.from(keys),
                    'name': name,
                    'unique': unique,
                    'partialFilterExpression': Map<String, Object>.from(
                      partialFilterExpression,
                    ),
                  },
                ],
              });
            } else {
              await collection.createIndex(
                keys: keys,
                unique: unique,
                name: name,
              );
            }
          } catch (_) {
            final indexes = await collection.getIndexes();
            final exists = indexes.any((index) => index['name'] == name);
            if (!exists) {
              rethrow;
            }
          }
        },
  );
}
