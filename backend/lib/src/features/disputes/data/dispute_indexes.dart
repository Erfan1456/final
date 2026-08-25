// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

const String disputesBookingUniqueIndexName = 'disputes_booking_unique';
const String disputesStatusIdDescIndexName = 'disputes_status_id_desc';
const String disputesCustomerIdDescIndexName = 'disputes_customer_id_desc';
const String disputesCleanerIdDescIndexName = 'disputes_cleaner_id_desc';
const String disputesCategoryStatusIdDescIndexName =
    'disputes_category_status_id_desc';

const String disputesBookingIdField = 'booking_id';
const String disputesStatusField = 'status';
const String disputesCustomerUserIdField = 'customer_user_id';
const String disputesCleanerUserIdField = 'cleaner_user_id';
const String disputesCategoryField = 'category';

typedef EnsureDisputeIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures `disputes` indexes for uniqueness, listing, and lookup.
Future<void> ensureDisputeIndexes({
  required EnsureDisputeIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.disputes,
    keys: const <String, dynamic>{disputesBookingIdField: 1},
    unique: true,
    name: disputesBookingUniqueIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.disputes,
    keys: const <String, dynamic>{disputesStatusField: 1, '_id': -1},
    unique: false,
    name: disputesStatusIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.disputes,
    keys: const <String, dynamic>{disputesCustomerUserIdField: 1, '_id': -1},
    unique: false,
    name: disputesCustomerIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.disputes,
    keys: const <String, dynamic>{disputesCleanerUserIdField: 1, '_id': -1},
    unique: false,
    name: disputesCleanerIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.disputes,
    keys: const <String, dynamic>{
      disputesCategoryField: 1,
      disputesStatusField: 1,
      '_id': -1,
    },
    unique: false,
    name: disputesCategoryStatusIdDescIndexName,
  );
}

/// Ensures dispute indexes on [db].
Future<void> ensureDisputeIndexesOnDb(Db db) {
  return ensureDisputeIndexes(
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
