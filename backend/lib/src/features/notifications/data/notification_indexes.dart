// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

const String notificationsUserIdDescIndexName = 'notifications_user_id_desc';
const String notificationsUserReadIdDescIndexName =
    'notifications_user_read_id_desc';
const String notificationsUserDedupeUniqueIndexName =
    'notifications_user_dedupe_unique';

const String notificationsUserIdField = 'user_id';
const String notificationsReadAtField = 'read_at';
const String notificationsDedupeKeyField = 'dedupe_key';

typedef EnsureNotificationIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures `notifications` indexes.
Future<void> ensureNotificationIndexes({
  required EnsureNotificationIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.notifications,
    keys: const <String, dynamic>{notificationsUserIdField: 1, '_id': -1},
    unique: false,
    name: notificationsUserIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.notifications,
    keys: const <String, dynamic>{
      notificationsUserIdField: 1,
      notificationsReadAtField: 1,
      '_id': -1,
    },
    unique: false,
    name: notificationsUserReadIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.notifications,
    keys: const <String, dynamic>{
      notificationsUserIdField: 1,
      notificationsDedupeKeyField: 1,
    },
    unique: true,
    name: notificationsUserDedupeUniqueIndexName,
  );
}

/// Ensures notification indexes on [db].
Future<void> ensureNotificationIndexesOnDb(Db db) {
  return ensureNotificationIndexes(
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
