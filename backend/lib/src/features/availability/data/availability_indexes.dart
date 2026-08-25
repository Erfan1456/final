import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Unique cleaner + start timestamp index.
///
/// Also serves listing by cleaner ordered by `start_at`. A second index named
/// `availability_slots_cleaner_start` with the same prefix is omitted as
/// redundant.
const String availabilitySlotsCleanerStartUniqueIndexName =
    'availability_slots_cleaner_start_unique';

/// Discovery/list by service and start.
const String availabilitySlotsServiceStartIndexName =
    'availability_slots_service_start';

/// Cleaner + service + start listing index.
const String availabilitySlotsCleanerServiceStartIndexName =
    'availability_slots_cleaner_service_start';

/// Cleaner owner field.
const String availabilitySlotsCleanerUserIdField = 'cleaner_user_id';

/// Platform service field.
const String availabilitySlotsServiceIdField = 'service_id';

/// Slot start field.
const String availabilitySlotsStartAtField = 'start_at';

/// Function used to ensure a MongoDB index without coupling tests to Atlas.
typedef EnsureAvailabilityIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures the approved `availability_slots` indexes.
///
/// `availability_slots_cleaner_start` is not created: the unique
/// `cleaner_user_id` + `start_at` index already covers that prefix.
Future<void> ensureAvailabilityIndexes({
  required EnsureAvailabilityIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.availabilitySlots,
    keys: const <String, dynamic>{
      availabilitySlotsCleanerUserIdField: 1,
      availabilitySlotsStartAtField: 1,
    },
    unique: true,
    name: availabilitySlotsCleanerStartUniqueIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.availabilitySlots,
    keys: const <String, dynamic>{
      availabilitySlotsServiceIdField: 1,
      availabilitySlotsStartAtField: 1,
    },
    unique: false,
    name: availabilitySlotsServiceStartIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.availabilitySlots,
    keys: const <String, dynamic>{
      availabilitySlotsCleanerUserIdField: 1,
      availabilitySlotsServiceIdField: 1,
      availabilitySlotsStartAtField: 1,
    },
    unique: false,
    name: availabilitySlotsCleanerServiceStartIndexName,
  );
}

/// Ensures approved availability indexes on [db].
Future<void> ensureAvailabilityIndexesOnDb(Db db) {
  return ensureAvailabilityIndexes(ensureIndex: _ensureIndexOnDb(db));
}

EnsureAvailabilityIndexFn _ensureIndexOnDb(Db db) {
  return ({
    required String collectionName,
    required Map<String, dynamic> keys,
    required bool unique,
    required String name,
  }) async {
    final collection = db.collection(collectionName);
    try {
      await collection.createIndex(keys: keys, unique: unique, name: name);
    } catch (_) {
      final indexes = await collection.getIndexes();
      final exists = indexes.any((index) => index['name'] == name);
      if (!exists) {
        rethrow;
      }
    }
  };
}
