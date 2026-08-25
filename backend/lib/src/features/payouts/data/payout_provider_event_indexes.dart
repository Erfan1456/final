import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Unique provider + provider_event_id index.
const String payoutEventsProviderEventUniqueIndexName =
    'payout_events_provider_event_unique';

/// Provider payout + created_at lookup index.
const String payoutEventsProviderPayoutCreatedIndexName =
    'payout_events_provider_payout_created';

/// Provider field.
const String payoutEventsProviderField = 'provider';

/// Provider event id field.
const String payoutEventsProviderEventIdField = 'provider_event_id';

/// Provider payout id field.
const String payoutEventsProviderPayoutIdField = 'provider_payout_id';

/// Created-at field.
const String payoutEventsCreatedAtField = 'created_at';

/// Function used to ensure a payout-event index in tests.
typedef EnsurePayoutProviderEventIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures the approved `payout_provider_events` indexes.
Future<void> ensurePayoutProviderEventIndexes({
  required EnsurePayoutProviderEventIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.payoutProviderEvents,
    keys: const <String, dynamic>{
      payoutEventsProviderField: 1,
      payoutEventsProviderEventIdField: 1,
    },
    unique: true,
    name: payoutEventsProviderEventUniqueIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.payoutProviderEvents,
    keys: const <String, dynamic>{
      payoutEventsProviderPayoutIdField: 1,
      payoutEventsCreatedAtField: 1,
    },
    unique: false,
    name: payoutEventsProviderPayoutCreatedIndexName,
  );
}

/// Ensures approved payout-event indexes on [db].
Future<void> ensurePayoutProviderEventIndexesOnDb(Db db) {
  return ensurePayoutProviderEventIndexes(
    ensureIndex:
        ({
          required String collectionName,
          required Map<String, dynamic> keys,
          required bool unique,
          required String name,
        }) async {
          final collection = db.collection(collectionName);
          try {
            await collection.createIndex(
              keys: keys,
              unique: unique,
              name: name,
            );
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
