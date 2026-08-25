import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Unique cleaner/service offering index.
const String cleanerServicesCleanerServiceUniqueIndexName =
    'cleaner_services_cleaner_service_unique';

/// Discovery listing by service and active flag.
const String cleanerServicesServiceActiveIdIndexName =
    'cleaner_services_service_active_id';

/// Discovery filtering by currency and rate.
const String cleanerServicesServiceCurrencyRateIdIndexName =
    'cleaner_services_service_currency_rate_id';

/// Cleaner owner field.
const String cleanerServicesCleanerUserIdField = 'cleaner_user_id';

/// Platform service field.
const String cleanerServicesServiceIdField = 'service_id';

/// Active flag field.
const String cleanerServicesIsActiveField = 'is_active';

/// Currency field.
const String cleanerServicesCurrencyCodeField = 'currency_code';

/// Hourly rate field.
const String cleanerServicesHourlyRateMinorField = 'hourly_rate_minor';

/// Function used to ensure a MongoDB index without coupling tests to Atlas.
typedef EnsureCleanerServiceIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures the approved `cleaner_services` indexes.
Future<void> ensureCleanerServiceIndexes({
  required EnsureCleanerServiceIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.cleanerServices,
    keys: const <String, dynamic>{
      cleanerServicesCleanerUserIdField: 1,
      cleanerServicesServiceIdField: 1,
    },
    unique: true,
    name: cleanerServicesCleanerServiceUniqueIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.cleanerServices,
    keys: const <String, dynamic>{
      cleanerServicesServiceIdField: 1,
      cleanerServicesIsActiveField: 1,
      '_id': 1,
    },
    unique: false,
    name: cleanerServicesServiceActiveIdIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.cleanerServices,
    keys: const <String, dynamic>{
      cleanerServicesServiceIdField: 1,
      cleanerServicesCurrencyCodeField: 1,
      cleanerServicesIsActiveField: 1,
      cleanerServicesHourlyRateMinorField: 1,
      '_id': 1,
    },
    unique: false,
    name: cleanerServicesServiceCurrencyRateIdIndexName,
  );
}

/// Ensures approved cleaner-service indexes on [db].
Future<void> ensureCleanerServiceIndexesOnDb(Db db) {
  return ensureCleanerServiceIndexes(ensureIndex: _ensureIndexOnDb(db));
}

EnsureCleanerServiceIndexFn _ensureIndexOnDb(Db db) {
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
