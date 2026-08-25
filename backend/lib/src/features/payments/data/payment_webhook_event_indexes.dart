import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Unique provider + provider_event_id index.
const String paymentWebhookEventsProviderEventUniqueIndexName =
    'payment_webhook_events_provider_event_unique';

/// Provider payment + created_at lookup index.
const String paymentWebhookEventsPaymentCreatedIndexName =
    'payment_webhook_events_payment_created';

/// Provider field.
const String paymentWebhookEventsProviderField = 'provider';

/// Provider event id field.
const String paymentWebhookEventsProviderEventIdField = 'provider_event_id';

/// Provider payment id field.
const String paymentWebhookEventsProviderPaymentIdField = 'provider_payment_id';

/// Created-at field.
const String paymentWebhookEventsCreatedAtField = 'created_at';

/// Function used to ensure a webhook-event index in tests.
typedef EnsurePaymentWebhookEventIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures the approved `payment_webhook_events` indexes.
Future<void> ensurePaymentWebhookEventIndexes({
  required EnsurePaymentWebhookEventIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.paymentWebhookEvents,
    keys: const <String, dynamic>{
      paymentWebhookEventsProviderField: 1,
      paymentWebhookEventsProviderEventIdField: 1,
    },
    unique: true,
    name: paymentWebhookEventsProviderEventUniqueIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.paymentWebhookEvents,
    keys: const <String, dynamic>{
      paymentWebhookEventsProviderPaymentIdField: 1,
      paymentWebhookEventsCreatedAtField: 1,
    },
    unique: false,
    name: paymentWebhookEventsPaymentCreatedIndexName,
  );
}

/// Ensures approved webhook-event indexes on [db].
Future<void> ensurePaymentWebhookEventIndexesOnDb(Db db) {
  return ensurePaymentWebhookEventIndexes(
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
