import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Partial unique active-slot reservation index.
const String bookingsActiveAvailabilitySlotUniqueIndexName =
    'bookings_active_availability_slot_unique';

/// Unique customer + idempotency-key index.
const String bookingsCustomerIdempotencyUniqueIndexName =
    'bookings_customer_idempotency_unique';

/// Customer list keyset index (`_id` descending).
const String bookingsCustomerIdDescIndexName = 'bookings_customer_id_desc';

/// Cleaner list keyset index (`_id` descending).
const String bookingsCleanerIdDescIndexName = 'bookings_cleaner_id_desc';

/// Cleaner active-interval overlap lookup index.
const String bookingsCleanerActiveStartIndexName =
    'bookings_cleaner_active_start';

/// Availability slot field.
const String bookingsAvailabilitySlotIdField = 'availability_slot_id';

/// Customer owner field.
const String bookingsCustomerUserIdField = 'customer_user_id';

/// Cleaner assignee field.
const String bookingsCleanerUserIdField = 'cleaner_user_id';

/// Idempotency key field.
const String bookingsIdempotencyKeyField = 'idempotency_key';

/// Explicit reservation concurrency field.
const String bookingsReservationActiveField = 'reservation_active';

/// Slot start field.
const String bookingsStartAtField = 'start_at';

/// Function used to ensure a booking index without coupling tests to Atlas.
typedef EnsureBookingIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
      Map<String, dynamic>? partialFilterExpression,
    });

/// Ensures the approved `bookings` indexes.
///
/// `bookings_availability_active` is omitted: the partial unique index on
/// `availability_slot_id` already covers active-reservation lookups by slot.
Future<void> ensureBookingIndexes({
  required EnsureBookingIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.bookings,
    keys: const <String, dynamic>{bookingsAvailabilitySlotIdField: 1},
    unique: true,
    name: bookingsActiveAvailabilitySlotUniqueIndexName,
    partialFilterExpression: const <String, dynamic>{
      bookingsReservationActiveField: true,
    },
  );
  await ensureIndex(
    collectionName: CollectionNames.bookings,
    keys: const <String, dynamic>{
      bookingsCustomerUserIdField: 1,
      bookingsIdempotencyKeyField: 1,
    },
    unique: true,
    name: bookingsCustomerIdempotencyUniqueIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.bookings,
    keys: const <String, dynamic>{
      bookingsCustomerUserIdField: 1,
      '_id': -1,
    },
    unique: false,
    name: bookingsCustomerIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.bookings,
    keys: const <String, dynamic>{
      bookingsCleanerUserIdField: 1,
      '_id': -1,
    },
    unique: false,
    name: bookingsCleanerIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.bookings,
    keys: const <String, dynamic>{
      bookingsCleanerUserIdField: 1,
      bookingsReservationActiveField: 1,
      bookingsStartAtField: 1,
    },
    unique: false,
    name: bookingsCleanerActiveStartIndexName,
  );
}

/// Ensures approved booking indexes on [db], including partial unique.
Future<void> ensureBookingIndexesOnDb(Db db) {
  return ensureBookingIndexes(
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
