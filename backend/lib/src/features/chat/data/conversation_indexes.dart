// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Unique booking_id conversation index.
const String conversationsBookingUniqueIndexName =
    'conversations_booking_unique';

/// Customer conversation list index.
const String conversationsCustomerLastMessageIndexName =
    'conversations_customer_last_message';

/// Cleaner conversation list index.
const String conversationsCleanerLastMessageIndexName =
    'conversations_cleaner_last_message';

const String conversationsBookingIdField = 'booking_id';
const String conversationsCustomerUserIdField = 'customer_user_id';
const String conversationsCleanerUserIdField = 'cleaner_user_id';
const String conversationsLastMessageAtField = 'last_message_at';

typedef EnsureConversationIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures `conversations` indexes.
///
/// Role-specific last-message indexes support `listForUser` by customer or
/// cleaner without a collection scan.
Future<void> ensureConversationIndexes({
  required EnsureConversationIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.conversations,
    keys: const <String, dynamic>{conversationsBookingIdField: 1},
    unique: true,
    name: conversationsBookingUniqueIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.conversations,
    keys: const <String, dynamic>{
      conversationsCustomerUserIdField: 1,
      conversationsLastMessageAtField: -1,
      '_id': -1,
    },
    unique: false,
    name: conversationsCustomerLastMessageIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.conversations,
    keys: const <String, dynamic>{
      conversationsCleanerUserIdField: 1,
      conversationsLastMessageAtField: -1,
      '_id': -1,
    },
    unique: false,
    name: conversationsCleanerLastMessageIndexName,
  );
}

/// Ensures conversation indexes on [db].
Future<void> ensureConversationIndexesOnDb(Db db) {
  return ensureConversationIndexes(
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
